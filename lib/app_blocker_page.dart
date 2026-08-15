import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// APP BLOCKER PAGE  –  shows only apps installed on THIS device
// Requires: device_apps, permission_handler (pubspec.yaml)
// Android permissions: QUERY_ALL_PACKAGES, PACKAGE_USAGE_STATS
// =============================================================================

// Native channel used to open the Usage Access settings screen
const _channel = MethodChannel('campus_twin/usage_access');

class AppBlockerPage extends StatefulWidget {
  const AppBlockerPage({super.key});
  @override
  State<AppBlockerPage> createState() => _AppBlockerPageState();
}

enum _LoadState { checkingPerm, needPerm, loading, ready, error }

class _AppBlockerPageState extends State<AppBlockerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  _LoadState _state = _LoadState.checkingPerm;
  List<ApplicationWithIcon> _apps = [];
  final Set<String> _blocked = {};
  bool _sessionActive = false;
  int _sessionMinutes = 25;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bootstrap();
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  // ── Boot flow ────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    setState(() => _state = _LoadState.checkingPerm);
    final granted = await _hasUsageAccess();
    if (!granted) { setState(() => _state = _LoadState.needPerm); return; }
    await _loadApps();
  }

  Future<bool> _hasUsageAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsageAccess');
      return result ?? false;
    } catch (_) {
      // channel not implemented yet — skip on non-Android
      return true;
    }
  }

  Future<void> _openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
    // After user returns, re-check
    await Future.delayed(const Duration(seconds: 1));
    await _bootstrap();
  }

  Future<void> _loadApps() async {
    setState(() => _state = _LoadState.loading);
    try {
      final all = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );
      final withIcon = all.whereType<ApplicationWithIcon>().toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
      setState(() { _apps = withIcon; _state = _LoadState.ready; });
    } catch (e) {
      setState(() { _errorMsg = e.toString(); _state = _LoadState.error; });
    }
  }

  // ── Blocking ─────────────────────────────────────────────────────────────

  void _toggle(String pkg) =>
      setState(() => _blocked.contains(pkg) ? _blocked.remove(pkg) : _blocked.add(pkg));

  void _toggleSession() {
    if (_blocked.isEmpty && !_sessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.selectAppFirst),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _sessionActive = !_sessionActive);
  }

  void _pickDuration() {
    if (_sessionActive) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationSheet(
        current: _sessionMinutes,
        onSelected: (v) => setState(() => _sessionMinutes = v),
      ),
    );
  }

  // ── Scaffold ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppPalette.textPrimary(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppStrings.appBlockerTitle,
            style: TextStyle(color: AppPalette.textPrimary(context),
                fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          if (_state == _LoadState.ready)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(AppStrings.blockedCount(_blocked.length),
                  style: const TextStyle(color: AppColors.purple,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() => switch (_state) {
    _LoadState.checkingPerm => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
    _LoadState.needPerm     => _PermissionScreen(onGrant: _openUsageSettings),
    _LoadState.loading      => _LoadingScreen(appCount: null),
    _LoadState.error        => _ErrorScreen(msg: _errorMsg ?? 'Unknown error', onRetry: _bootstrap),
    _LoadState.ready        => _readyView(),
  };

  Widget _readyView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _StatusCard(pulse: _pulse, active: _sessionActive,
            blockedCount: _blocked.length, minutes: _sessionMinutes),
        const SizedBox(height: 20),
        _SessionBar(active: _sessionActive, minutes: _sessionMinutes,
            onPickDuration: _pickDuration, onToggle: _toggleSession),
        const SizedBox(height: 24),
        _SectionHeader(title: AppStrings.installedApps,
            trailing: AppStrings.appsFound(_apps.length)),
        const SizedBox(height: 12),
        _AppGrid(apps: _apps, blocked: _blocked, onToggle: _toggle),
        const SizedBox(height: 24),
        const _TipsCard(),
      ],
    );
  }
}

// =============================================================================
// PERMISSION SCREEN
// =============================================================================

class _PermissionScreen extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionScreen({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple.withValues(alpha: 0.15),
                  AppColors.purple.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded,
                color: AppColors.purple, size: 44),
          ),
          const SizedBox(height: 28),
          Text(AppStrings.usageAccessTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary(context))),
          const SizedBox(height: 12),
          Text(
            AppStrings.usageAccessBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppPalette.textSecondary(context),
                height: 1.6),
          ),
          const SizedBox(height: 32),
          // Permission steps
          ...[AppStrings.openSettings, AppStrings.findCampusTwin, AppStrings.enableUsageAccess]
              .asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              CircleAvatar(radius: 14,
                  backgroundColor: AppColors.purple.withValues(alpha: 0.12),
                  child: Text('${e.key + 1}',
                      style: const TextStyle(color: AppColors.purple,
                          fontSize: 12, fontWeight: FontWeight.w800))),
              const SizedBox(width: 14),
              Text(e.value,
                  style: TextStyle(fontSize: 14,
                      color: AppPalette.textPrimary(context), fontWeight: FontWeight.w600)),
            ]),
          )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(AppStrings.openSettings,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LOADING + ERROR SCREENS
// =============================================================================

class _LoadingScreen extends StatelessWidget {
  final int? appCount;
  const _LoadingScreen({this.appCount});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: AppColors.purple),
      const SizedBox(height: 16),
      Text(AppStrings.scanningApps,
          style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14)),
    ]),
  );
}

class _ErrorScreen extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
        const SizedBox(height: 16),
        Text(AppStrings.failedToLoadApps,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: AppPalette.textPrimary(context))),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 13)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple,
                foregroundColor: Colors.white),
            child: Text(AppStrings.retry)),
      ]),
    ),
  );
}

// =============================================================================
// STATUS CARD
// =============================================================================

class _StatusCard extends StatelessWidget {
  final Animation<double> pulse;
  final bool active;
  final int blockedCount, minutes;
  const _StatusCard({required this.pulse, required this.active,
      required this.blockedCount, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, _) {
        final glow = active
            ? Color.lerp(const Color(0xFF16A34A), const Color(0xFF4ADE80), pulse.value)!
            : AppColors.purple;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [const Color(0xFF14532D), const Color(0xFF166534)]
                  : [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(active ? Icons.shield_rounded : Icons.shield_outlined,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active ? AppStrings.focusModeActive : AppStrings.focusModeOff,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(active
                    ? AppStrings.focusActiveSub(blockedCount, minutes)
                    : AppStrings.focusOffSub,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5)),
              ],
            )),
          ]),
        );
      },
    );
  }
}

// =============================================================================
// SESSION BAR
// =============================================================================

class _SessionBar extends StatelessWidget {
  final bool active;
  final int minutes;
  final VoidCallback onPickDuration, onToggle;
  const _SessionBar({required this.active, required this.minutes,
      required this.onPickDuration, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: onPickDuration,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPalette.border(context).withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.timer_outlined, color: AppColors.purple, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.duration, style: TextStyle(color: AppPalette.textSecondary(context),
                  fontSize: 11, fontWeight: FontWeight.w500)),
              Text(AppStrings.minutes(minutes), style: TextStyle(color: AppPalette.textPrimary(context),
                  fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const Spacer(),
            if (!active) Icon(Icons.keyboard_arrow_down_rounded,
                color: AppPalette.textSecondary(context), size: 20),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)])
                : const LinearGradient(colors: [AppColors.purple, Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: (active ? const Color(0xFFDC2626) : AppColors.purple)
                  .withValues(alpha: 0.35),
              blurRadius: 12, offset: const Offset(0, 4),
            )],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(active ? AppStrings.stop : AppStrings.start,
                style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      )),
    ]);
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title, trailing;
  const _SectionHeader({required this.title, required this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 16,
        decoration: BoxDecoration(color: AppColors.purple,
            borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(color: AppPalette.textPrimary(context),
        fontSize: 16, fontWeight: FontWeight.w800)),
    const Spacer(),
    Text(trailing, style: TextStyle(color: AppPalette.textSecondary(context),
        fontSize: 12, fontWeight: FontWeight.w500)),
  ]);
}

// =============================================================================
// APP GRID  –  real device apps
// =============================================================================

class _AppGrid extends StatelessWidget {
  final List<ApplicationWithIcon> apps;
  final Set<String> blocked;
  final void Function(String pkg) onToggle;
  const _AppGrid({required this.apps, required this.blocked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: apps.length,
      itemBuilder: (_, i) {
        final app = apps[i];
        final isBlocked = blocked.contains(app.packageName);
        return GestureDetector(
          onTap: () => onToggle(app.packageName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isBlocked
                  ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isBlocked
                    ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                    : AppPalette.border(context).withValues(alpha: 0.5),
                width: isBlocked ? 1.8 : 1,
              ),
              boxShadow: isBlocked
                  ? [BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                      blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    app.icon,
                    width: 46, height: 46,
                    errorBuilder: (_, _, _) => Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apps_rounded, color: AppColors.purple, size: 24),
                    ),
                  ),
                ),
                if (isBlocked)
                  Positioned(right: 0, top: 0,
                    child: Container(width: 16, height: 16,
                      decoration: const BoxDecoration(
                          color: Color(0xFFDC2626), shape: BoxShape.circle),
                      child: const Icon(Icons.block_rounded,
                          color: Colors.white, size: 10)),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(app.appName,
                textAlign: TextAlign.center, maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isBlocked ? const Color(0xFFDC2626) : AppPalette.textPrimary(context)),
              ),
              if (isBlocked) ...[
                const SizedBox(height: 3),
                Text(AppStrings.blocked,
                    style: const TextStyle(fontSize: 9.5,
                        color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        );
      },
    );
  }
}

// =============================================================================
// TIPS CARD
// =============================================================================

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) {
    final tips = [
      AppStrings.tip1,
      AppStrings.tip2,
      AppStrings.tip3,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.purple, size: 18),
          const SizedBox(width: 8),
          Text(AppStrings.focusTips, style: const TextStyle(color: AppColors.purple,
              fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t, style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 12.5)),
        )),
      ]),
    );
  }
}

// =============================================================================
// DURATION PICKER SHEET
// =============================================================================

class _DurationSheet extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelected;
  const _DurationSheet({required this.current, required this.onSelected});

  static final _opts = [
    (15, AppStrings.quickFocus, Icons.coffee_rounded),
    (25, AppStrings.pomodoro, Icons.timer_rounded),
    (45, AppStrings.deepWork, Icons.psychology_rounded),
    (60, AppStrings.oneHour, Icons.hourglass_bottom_rounded),
    (90, AppStrings.longSession, Icons.auto_awesome_rounded),
    (120, AppStrings.powerBlock, Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 5,
            decoration: BoxDecoration(color: AppPalette.border(context),
                borderRadius: BorderRadius.circular(999)))),
        const SizedBox(height: 16),
        Text(AppStrings.selectDuration,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary(context))),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: _opts.map((o) {
            final sel = o.$1 == current;
            return GestureDetector(
              onTap: () { onSelected(o.$1); Navigator.of(context).pop(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: sel ? AppColors.purple.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? AppColors.purple.withValues(alpha: 0.4)
                        : AppPalette.border(context).withValues(alpha: 0.5),
                    width: sel ? 1.8 : 1,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(o.$3, color: sel ? AppColors.purple : AppPalette.textSecondary(context), size: 22),
                  const SizedBox(height: 4),
                  Text('${o.$1}m', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: sel ? AppColors.purple : AppPalette.textPrimary(context))),
                  Text(o.$2, style: TextStyle(fontSize: 9.5,
                      color: sel ? AppColors.purple.withValues(alpha: 0.8) : AppPalette.textSecondary(context))),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}
