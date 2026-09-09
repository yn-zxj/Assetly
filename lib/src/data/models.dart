class AssetItem {
  const AssetItem({
    required this.id,
    required this.name,
    this.description = '',
    this.categoryId = '',
    this.categoryName = '',
    this.locationId = '',
    this.locationPath = '',
    this.purchaseDate = '',
    this.purchasePrice = 0,
    this.quantity = 1,
    this.imagePath = '',
    this.icon = '📦',
    this.status = 'active',
    this.isMedicine = false,
    this.barcode = '',
    this.warrantyExpiry = '',
    this.shelfLifeExpiry = '',
    this.retiredDate = '',
    this.resaleAmount = 0,
  });

  final String id,
      name,
      description,
      categoryId,
      categoryName,
      locationId,
      locationPath;
  final String purchaseDate,
      imagePath,
      icon,
      status,
      barcode,
      warrantyExpiry,
      shelfLifeExpiry,
      retiredDate;
  final double purchasePrice, resaleAmount;
  final int quantity;
  final bool isMedicine;

  int get daysInService {
    final start = DateTime.tryParse(purchaseDate);
    if (start == null) return 1;
    final end = status == 'disposed'
        ? DateTime.tryParse(retiredDate) ?? DateTime.now()
        : DateTime.now();
    return end.difference(start).inDays.abs() + 1;
  }

  double get dailyCost =>
      ((purchasePrice - (status == 'disposed' ? resaleAmount : 0)) /
              daysInService)
          .clamp(0, double.infinity);

  factory AssetItem.fromMap(Map<String, Object?> m) => AssetItem(
    id: '${m['id']}',
    name: '${m['name']}',
    description: '${m['description'] ?? ''}',
    categoryId: '${m['category_id'] ?? ''}',
    categoryName: '${m['category_name'] ?? ''}',
    locationId: '${m['location_id'] ?? ''}',
    locationPath: '${m['location_full_path'] ?? ''}',
    purchaseDate: '${m['purchase_date'] ?? ''}',
    purchasePrice: (m['purchase_price'] as num?)?.toDouble() ?? 0,
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    imagePath: '${m['image_path'] ?? ''}',
    icon: '${m['icon'] ?? '📦'}',
    status: '${m['status'] ?? 'active'}',
    isMedicine: (m['is_medicine'] as num?)?.toInt() == 1,
    barcode: '${m['barcode'] ?? ''}',
    warrantyExpiry: '${m['warranty_expiry'] ?? ''}',
    shelfLifeExpiry: '${m['shelf_life_expiry'] ?? ''}',
    retiredDate: '${m['retired_date'] ?? ''}',
    resaleAmount: (m['resale_amount'] as num?)?.toDouble() ?? 0,
  );
}

class Medicine {
  const Medicine({
    required this.id,
    required this.itemId,
    required this.name,
    this.icon = '💊',
    this.medicineType = 'internal',
    this.expiryDate = '',
    this.dosageInstructions = '',
    this.remainingQuantity = 0,
    this.unit = '片',
    this.manufacturer = '',
    this.barcode = '',
    this.isTaking = false,
    this.frequencyType = 'daily',
    this.frequencyDays = 1,
    this.weekDays = '',
    this.timeSlots = '',
    this.durationStart = '',
    this.durationEnd = '',
    this.locationPath = '',
    this.locationId = '',
    this.purchaseDate = '',
    this.purchasePrice = 0,
  });
  final String id,
      itemId,
      name,
      icon,
      medicineType,
      expiryDate,
      dosageInstructions,
      unit,
      manufacturer,
      barcode;
  final String frequencyType,
      weekDays,
      timeSlots,
      durationStart,
      durationEnd,
      locationPath,
      locationId,
      purchaseDate;
  final double purchasePrice;
  final double remainingQuantity;
  final int frequencyDays;
  final bool isTaking;

  List<String> get slots => timeSlots
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  int get daysUntilExpiry {
    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return 999999;
    final today = DateTime.now();
    return DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  factory Medicine.fromMap(Map<String, Object?> m) => Medicine(
    id: '${m['id']}',
    itemId: '${m['item_id']}',
    name: '${m['name'] ?? ''}',
    icon: '${m['icon'] ?? '💊'}',
    medicineType: '${m['medicine_type'] ?? 'internal'}',
    expiryDate: '${m['expiry_date'] ?? ''}',
    dosageInstructions: '${m['dosage_instructions'] ?? ''}',
    remainingQuantity: (m['remaining_quantity'] as num?)?.toDouble() ?? 0,
    unit: '${m['unit'] ?? '片'}',
    manufacturer: '${m['manufacturer'] ?? ''}',
    barcode: '${m['barcode'] ?? ''}',
    isTaking: (m['is_taking'] as num?)?.toInt() == 1,
    frequencyType: '${m['frequency_type'] ?? 'daily'}',
    frequencyDays: (m['frequency_days'] as num?)?.toInt() ?? 1,
    weekDays: '${m['week_days'] ?? ''}',
    timeSlots: '${m['time_slots'] ?? ''}',
    durationStart: '${m['duration_start'] ?? ''}',
    durationEnd: '${m['duration_end'] ?? ''}',
    locationPath: '${m['location_full_path'] ?? ''}',
    locationId: '${m['location_id'] ?? ''}',
    purchaseDate: '${m['purchase_date'] ?? ''}',
    purchasePrice: (m['purchase_price'] as num?)?.toDouble() ?? 0,
  );
}

class StorageLocation {
  const StorageLocation({
    required this.id,
    required this.name,
    required this.fullPath,
    this.icon = '📍',
    this.parentId,
    this.level = 0,
    this.itemCount = 0,
    this.totalValue = 0,
  });
  final String id, name, fullPath, icon;
  final String? parentId;
  final int level, itemCount;
  final double totalValue;
  factory StorageLocation.fromMap(Map<String, Object?> m) => StorageLocation(
    id: '${m['id']}',
    name: '${m['name']}',
    fullPath: '${m['full_path'] ?? m['name']}',
    icon: '${m['icon'] ?? '📍'}',
    parentId: m['parent_id'] as String?,
    level: (m['level'] as num?)?.toInt() ?? 0,
    itemCount: (m['item_count'] as num?)?.toInt() ?? 0,
    totalValue: (m['total_value'] as num?)?.toDouble() ?? 0,
  );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.count = 0,
  });
  final String id, name, icon, color;
  final int count;
  factory Category.fromMap(Map<String, Object?> m) => Category(
    id: '${m['id']}',
    name: '${m['name']}',
    icon: '${m['icon'] ?? ''}',
    color: '${m['color'] ?? '#71717A'}',
    count: (m['item_count'] as num?)?.toInt() ?? 0,
  );
}

class MedicationLog {
  const MedicationLog({
    required this.id,
    required this.medicineId,
    required this.takenAt,
    required this.quantity,
    required this.status,
  });
  final String id, medicineId, takenAt, status;
  final double quantity;
}
