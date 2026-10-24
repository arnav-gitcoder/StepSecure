import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/models/alert_model.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/services/device_monitor.dart';
import 'package:stepsecure_app/services/firestore_service.dart';
import 'package:stepsecure_app/utils/alert_style.dart';
import 'package:stepsecure_app/utils/data_error_helper.dart';
import 'package:stepsecure_app/utils/date_time_helper.dart';
import 'package:stepsecure_app/widgets/dashboard_card.dart';
import 'package:stepsecure_app/widgets/status_indicator.dart';

/// Caregiver dashboard. Everything shown here comes from real data
/// (the linked wearable and the user's alert history). When something isn't
/// available, the screen says so instead of showing placeholder numbers.
class HomeScreen extends StatefulWidget {
  /// Shared wearable state, owned by MainNavigation.
  final DeviceMonitor monitor;

  /// Called with the bottom-nav tab index to switch to.
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.monitor,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tab indexes in MainNavigation.
  static const int _tabMonitor = 1;
  static const int _tabAlerts = 2;
  static const int _tabContacts = 3;
  static const int _tabSettings = 4;

  final FirestoreService _firestore = FirestoreService();
  late Stream<List<AlertModel>> _alertsStream;

  @override
  void initState() {
    super.initState();
    _alertsStream = _openAlerts();
  }

  Stream<List<AlertModel>> _openAlerts() {
    try {
      final uid = AuthService.instance.currentUser?.uid;
      if (uid == null) return const Stream<List<AlertModel>>.empty();
      return _firestore.alertsStream(uid, limit: 20);
    } catch (e) {
      return Stream<List<AlertModel>>.error(e);
    }
  }

  void _retryAlerts() {
    setState(() => _alertsStream = _openAlerts());
  }

  void _goTo(int tab) => widget.onNavigateToTab?.call(tab);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "StepSecure",
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _alertsStream,
        builder: (context, alertSnap) {
          return ListenableBuilder(
            listenable: widget.monitor,
            builder: (context, _) => _buildBody(context, alertSnap),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<AlertModel>> alertSnap,
  ) {
    final alerts = alertSnap.data ?? const <AlertModel>[];
    final falls = alerts.where(isFallAlert).toList();
    final unacknowledgedFalls = falls.where((a) => a.needsAttention).length;
    final latestFall = falls.isEmpty ? null : falls.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StatusIndicator.fromMonitor(
            widget.monitor,
            unacknowledgedFalls: unacknowledgedFalls,
          ),
          const SizedBox(height: 20),
          _buildWearableCard(context),
          const SizedBox(height: 20),
          _buildLatestFallCard(
            context,
            alertSnap: alertSnap,
            latestFall: latestFall,
          ),
          const SizedBox(height: 20),
          _buildQuickAccess(context),
        ],
      ),
    );
  }

  // ---------- Wearable card ----------

  Widget _buildWearableCard(BuildContext context) {
    final m = widget.monitor;
    final cs = Theme.of(context).colorScheme;
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: cs.onSurface.withValues(alpha: 0.6),
    );

    String subtitle;
    IconData icon;
    Color color;
    Widget? child;

    switch (m.phase) {
      case MonitorPhase.loading:
        subtitle = 'Checking…';
        icon = Icons.sync;
        color = AppColors.textLight;
        child = null;
        break;
      case MonitorPhase.noDevice:
        subtitle = 'No wearable linked';
        icon = Icons.watch_outlined;
        color = AppColors.textLight;
        child = Text(
          'No wearable is linked to this account yet.',
          style: subtitleStyle,
        );
        break;
      case MonitorPhase.error:
        subtitle = 'Status unavailable';
        icon = Icons.error_outline;
        color = AppColors.warning;
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.errorMessage ?? 'Something went wrong.', style: subtitleStyle),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: m.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        );
        break;
      case MonitorPhase.ready:
        final connection = m.connection;
        final monitoring = m.status.monitoringActive;
        final battery = m.status.batteryPercent;
        final last = m.lastCommunication;

        subtitle = connectionLabel(connection);
        icon = connectionIcon(connection);
        color = connectionColor(connection);
        child = Column(
          children: [
            _infoRow(
              context,
              'Last communication',
              last == null
                  ? 'No data received yet'
                  : DateTimeHelper.timeAgo(last, now: m.serverNow),
            ),
            const SizedBox(height: 8),
            _infoRow(
              context,
              'Monitoring',
              monitoring == null
                  ? 'Not reported'
                  : (monitoring ? 'Active' : 'Paused'),
            ),
            // Only shown if the wearable actually reports a battery level.
            if (battery != null) ...[
              const SizedBox(height: 8),
              _infoRow(context, 'Battery', '$battery%'),
            ],
          ],
        );
        break;
    }

    return DashboardCard(
      title: 'Wearable',
      subtitle: subtitle,
      icon: icon,
      iconColor: color,
      onTap: () => _goTo(_tabMonitor),
      trailing: Icon(
        Icons.chevron_right,
        color: cs.onSurface.withValues(alpha: 0.5),
      ),
      child: child,
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.cardSubtitle.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppStyles.bodyMedium.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Latest fall card ----------

  Widget _buildLatestFallCard(
    BuildContext context, {
    required AsyncSnapshot<List<AlertModel>> alertSnap,
    required AlertModel? latestFall,
  }) {
    final cs = Theme.of(context).colorScheme;
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: cs.onSurface.withValues(alpha: 0.6),
    );
    final bodyStyle = AppStyles.bodyMedium.copyWith(color: cs.onSurface);

    Widget child;

    if (alertSnap.hasError) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DataErrorHelper.friendlyMessage(alertSnap.error!),
            style: subtitleStyle,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _retryAlerts,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      );
    } else if (!alertSnap.hasData) {
      child = const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (latestFall == null) {
      child = Text(
        'No fall events recorded. Falls reported by the wearable will '
        'appear here.',
        style: subtitleStyle,
      );
    } else {
      final style = alertStyleFor(latestFall);
      final when = latestFall.timestamp == null
          ? 'Unknown time'
          : '${DateTimeHelper.timeAgo(latestFall.timestamp)} • '
              '${DateTimeHelper.formatDateTime(latestFall.timestamp)}';
      final needsAttention = latestFall.needsAttention;

      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  latestFall.displayTitle,
                  style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(when, style: subtitleStyle),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                needsAttention
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                size: 18,
                color: needsAttention ? AppColors.danger : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                needsAttention ? 'Needs attention' : 'Acknowledged',
                style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(notificationLabel(latestFall), style: subtitleStyle),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _goTo(_tabAlerts),
              child: const Text('View all alerts'),
            ),
          ),
        ],
      );
    }

    return DashboardCard(
      title: 'Latest fall event',
      icon: Icons.history,
      iconColor: AppColors.primary,
      child: child,
    );
  }

  // ---------- Quick access ----------

  Widget _buildQuickAccess(BuildContext context) {
    return DashboardCard(
      title: 'Quick Access',
      icon: Icons.flash_on,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.monitor_heart,
                  label: 'Live Monitor',
                  onTap: () => _goTo(_tabMonitor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.notifications,
                  label: 'Alerts',
                  onTap: () => _goTo(_tabAlerts),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.people,
                  label: 'Contacts',
                  onTap: () => _goTo(_tabContacts),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => _goTo(_tabSettings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}