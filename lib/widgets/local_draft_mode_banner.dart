import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme.dart';

class LocalDraftModeBadge extends StatelessWidget {
  const LocalDraftModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminService.localDraftMode,
      builder: (context, isLocal, _) => Chip(
        avatar: Icon(
          isLocal ? Icons.shield_outlined : Icons.cloud_outlined,
          size: 15,
        ),
        label: Text(isLocal ? 'LOCAL DRAFT · محلي' : 'LIVE · مباشر'),
        backgroundColor: isLocal
            ? AppTheme.success.withValues(alpha: 0.12)
            : AppTheme.danger.withValues(alpha: 0.12),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          color: isLocal ? AppTheme.success : AppTheme.danger,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LocalDraftModeBanner extends StatelessWidget {
  final Future<void> Function()? onChanged;

  const LocalDraftModeBanner({super.key, this.onChanged});

  Future<void> _changeMode(BuildContext context, bool enabled) async {
    final service = AdminService.instance;
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable live database writes?'),
          content: const Text(
            'Local Draft Mode will turn off. Place and tour changes may be '
            'written to the configured Supabase project.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep local drafts'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue to live mode'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await service.setLocalDraftMode(enabled);
      await onChanged?.call();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not change draft mode: $error'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminService.localDraftMode,
      builder: (context, isLocal, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isLocal
              ? AppTheme.success.withValues(alpha: 0.08)
              : AppTheme.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocal
                ? AppTheme.success.withValues(alpha: 0.3)
                : AppTheme.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLocal ? Icons.shield_outlined : Icons.cloud_outlined,
              color: isLocal ? AppTheme.success : AppTheme.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isLocal
                    ? 'Local Draft Mode ON — edits stay on this device. '
                          'وضع المسودة المحلي مفعّل'
                    : 'Live mode — edits may reach Supabase. '
                          'وضع قاعدة البيانات المباشرة',
                style: TextStyle(
                  color: isLocal ? AppTheme.success : AppTheme.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Switch.adaptive(
              value: isLocal,
              activeThumbColor: AppTheme.success,
              onChanged: (value) => _changeMode(context, value),
            ),
          ],
        ),
      ),
    );
  }
}
