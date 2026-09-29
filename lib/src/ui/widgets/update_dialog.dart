import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_service.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppRelease release,
  required String currentVersion,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(LucideIcons.downloadCloud),
      title: Text('发现新版本 ${release.tagName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前版本：v$currentVersion'),
              if (release.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  release.notes,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('稍后再说'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final url = Uri.parse(release.downloadUrl ?? release.releaseUrl);
            final opened = await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
            if (dialogContext.mounted && opened) {
              Navigator.pop(dialogContext);
            } else if (dialogContext.mounted) {
              ScaffoldMessenger.of(
                dialogContext,
              ).showSnackBar(const SnackBar(content: Text('无法打开更新下载页')));
            }
          },
          icon: const Icon(LucideIcons.download, size: 18),
          label: const Text('下载更新'),
        ),
      ],
    ),
  );
}
