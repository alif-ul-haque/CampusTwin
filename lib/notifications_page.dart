import 'package:flutter/material.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/l10n.dart';

/// Mock notification center. Reads from [AppSettings].
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background(context),
      appBar: AppBar(
        backgroundColor: AppPalette.background(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppPalette.textPrimary(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.notificationCenter,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: AppSettings.instance.markAllRead,
            child: Text(
              AppStrings.markAllRead,
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) {
          final s = AppSettings.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _enableCard(s, context),
              const SizedBox(height: 16),
              if (!s.notificationsEnabled)
                _offCard(context)
              else if (s.notifications.every((n) => n.read))
                _emptyCard(context)
              else
                ...s.notifications.map((n) => _notifCard(s, n, context)),
            ],
          );
        },
      ),
    );
  }

  Widget _enableCard(AppSettings s, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF4F46E5),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.notifications,
              style: TextStyle(
                color: AppPalette.textPrimary(context),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: s.notificationsEnabled,
            activeTrackColor: const Color(0xFF4F46E5),
            onChanged: (v) => s.notificationsEnabled = v,
          ),
        ],
      ),
    );
  }

  Widget _offCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 46,
            color: AppPalette.textSecondary(context),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.notificationsOffTitle,
            style: TextStyle(
              color: AppPalette.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.notificationsOffBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppPalette.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 40,
            color: AppPalette.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.noNotifications,
            style: TextStyle(
              color: AppPalette.textSecondary(context),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifCard(
    AppSettings s,
    AppNotification n,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: n.read
            ? AppPalette.card(context)
            : const Color(0xFF4F46E5).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: n.read
              ? AppPalette.border(context)
              : const Color(0xFF4F46E5).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(n.icon, color: n.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          color: AppPalette.textPrimary(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: TextStyle(
                    color: AppPalette.textSecondary(context),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  n.time,
                  style: TextStyle(
                    color: AppPalette.textSecondary(context)
                        .withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
