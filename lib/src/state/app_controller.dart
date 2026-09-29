import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';

class AppController extends ChangeNotifier {
  AppController(
    this.database,
    this.notifications, {
    UpdateService? updateService,
  }) : updateService = updateService ?? UpdateService();
  final AppDatabase database;
  final NotificationService notifications;
  final UpdateService updateService;
  List<AssetItem> items = [];
  List<Medicine> medicines = [];
  List<StorageLocation> locations = [];
  List<Category> categories = [];
  Set<String> takenMedicineIdsToday = {};
  ThemeMode themeMode = ThemeMode.system;
  Color accent = const Color(0xFF10B981);
  bool separateAiModels = false;
  bool loading = true;
  String appVersion = '';
  String buildNumber = '';
  AppRelease? availableUpdate;
  String? updateError;
  DateTime? lastUpdateCheck;
  bool checkingForUpdates = false;
  bool checkedForUpdates = false;
  Future<AppRelease?>? _activeUpdateCheck;

  static const updateCheckInterval = Duration(hours: 12);

  String get displayVersion => appVersion.isEmpty ? '开发版' : 'v$appVersion';

  Future<void> initialize() async {
    try {
      final package = await PackageInfo.fromPlatform();
      appVersion = package.version;
      buildNumber = package.buildNumber;
    } catch (_) {
      // Version information is cosmetic and must not block app startup.
    }
    final prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values.firstWhere(
      (x) => x.name == prefs.getString('theme_mode'),
      orElse: () => ThemeMode.system,
    );
    accent = _accentFor(prefs.getString('accent') ?? 'emerald');
    separateAiModels = await database.getSetting('ai_model_mode') == 'separate';
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    final result = await (
      database.getItems(),
      database.getMedicines(),
      database.getLocations(),
      database.getCategories(),
      database.getTakenMedicineIdsToday(),
    ).wait;
    items = result.$1;
    medicines = result.$2;
    locations = result.$3;
    categories = result.$4;
    takenMedicineIdsToday = result.$5;
    loading = false;
    notifyListeners();
  }

  double get totalValue => items
      .where((x) => x.status != 'disposed')
      .fold(0, (a, b) => a + b.purchasePrice);
  double get totalDailyCost => items
      .where((x) => x.status == 'active')
      .fold(0, (a, b) => a + b.dailyCost);
  int get activeCount => items.where((x) => x.status == 'active').length;
  List<Medicine> get takingMedicines =>
      medicines.where((x) => x.isTaking).toList();
  List<Medicine> get expiringMedicines =>
      medicines.where((x) => x.daysUntilExpiry <= 30).toList();

  Future<void> setTheme(ThemeMode value) async {
    themeMode = value;
    (await SharedPreferences.getInstance()).setString('theme_mode', value.name);
    notifyListeners();
  }

  Future<void> setAccent(String name) async {
    accent = _accentFor(name);
    (await SharedPreferences.getInstance()).setString('accent', name);
    notifyListeners();
  }

  Future<void> setAiModelMode(bool separate) async {
    separateAiModels = separate;
    notifyListeners();
    await database.setSetting(
      'ai_model_mode',
      separate ? 'separate' : 'shared',
    );
  }

  Color _accentFor(String name) =>
      const {
        'zinc': Color(0xFF52525B),
        'slate': Color(0xFF475569),
        'blue': Color(0xFF2563EB),
        'emerald': Color(0xFF10B981),
        'violet': Color(0xFF7C3AED),
        'rose': Color(0xFFE11D48),
        'amber': Color(0xFFD97706),
      }[name] ??
      const Color(0xFF10B981);

  Future<void> saveItem(Map<String, Object?> values, {String? id}) async {
    await database.saveItem(values, id: id);
    await refresh();
  }

  Future<void> deleteItem(String id) async {
    await database.deleteItem(id);
    await refresh();
  }

  bool wasTakenToday(Medicine medicine) =>
      takenMedicineIdsToday.contains(medicine.id);

  Future<void> takeDose(Medicine medicine, {double quantity = 1}) async {
    final updated = await database.recordDose(medicine, quantity: quantity);
    await refresh();
    if (updated != null) {
      try {
        await notifications.syncMedicine(updated);
      } catch (_) {
        // Recording a dose must still succeed when notifications are unavailable.
      }
    }
  }

  Future<void> saveMedicine(
    Map<String, Object?> item,
    Map<String, Object?> medicine, {
    Medicine? existing,
  }) async {
    await database.saveMedicine(
      item,
      medicine,
      itemId: existing?.itemId,
      medicineId: existing?.id,
    );
    await refresh();
    final saved = existing == null
        ? medicines.firstWhere((m) => m.name == item['name'])
        : medicines.firstWhere((m) => m.id == existing.id);
    try {
      await notifications.syncMedicine(saved);
    } catch (_) {
      // Saving local data must not fail when notification permission is absent.
    }
  }

  Future<void> deleteMedicine(Medicine medicine) async {
    await notifications.cancelMedicine(medicine);
    await database.deleteMedicine(medicine);
    await refresh();
  }

  Future<void> addLocation(
    String name, {
    String icon = '📍',
    String? parentId,
  }) async {
    await database.saveLocation(name, icon: icon, parentId: parentId);
    await refresh();
  }

  Future<void> updateLocation(
    String id, {
    required String name,
    required String icon,
    String? parentId,
  }) async {
    await database.updateLocation(
      id,
      name: name,
      icon: icon,
      parentId: parentId,
    );
    await refresh();
  }

  Future<void> deleteLocation(String id) async {
    await database.deleteLocation(id);
    await refresh();
  }

  Future<AppRelease?> checkForUpdates({bool force = false}) async {
    final active = _activeUpdateCheck;
    if (active != null) return active;
    final task = _checkForUpdates(force: force);
    _activeUpdateCheck = task;
    try {
      return await task;
    } finally {
      _activeUpdateCheck = null;
    }
  }

  Future<AppRelease?> _checkForUpdates({required bool force}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCheck = DateTime.tryParse(
      prefs.getString('last_update_check_at') ?? '',
    );
    lastUpdateCheck = savedCheck;
    if (!force &&
        savedCheck != null &&
        DateTime.now().difference(savedCheck) < updateCheckInterval) {
      return availableUpdate;
    }

    checkingForUpdates = true;
    updateError = null;
    notifyListeners();
    try {
      if (appVersion.isEmpty) throw Exception('无法读取当前应用版本');
      final release = await updateService.getLatestRelease();
      availableUpdate =
          UpdateService.isNewerVersion(release.version, appVersion)
          ? release
          : null;
      checkedForUpdates = true;
      return availableUpdate;
    } catch (error) {
      updateError = '$error'.replaceFirst('Exception: ', '');
      checkedForUpdates = true;
      return null;
    } finally {
      checkingForUpdates = false;
      lastUpdateCheck = DateTime.now();
      await prefs.setString(
        'last_update_check_at',
        lastUpdateCheck!.toIso8601String(),
      );
      notifyListeners();
    }
  }

  Future<bool> enableReminders() async {
    final granted = await notifications.requestPermissions();
    if (granted) {
      for (final m in takingMedicines) {
        await notifications.scheduleMedicine(m);
      }
    }
    return granted;
  }
}
