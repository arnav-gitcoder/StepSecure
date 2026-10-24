import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/services/device_monitor.dart';
import 'package:stepsecure_app/utils/date_time_helper.dart';
import 'package:stepsecure_app/widgets/sensor_tile.dart';
import 'package:stepsecure_app/widgets/status_indicator.dart';

/// Live view of the linked wearable. Shows only what the device has really
/// published: missing or out-of-date readings appear as "—" / "No data",
/// never as zeros or sample numbers.
class LiveMonitorScreen extends StatelessWidget {
  /// Shared wearable state, owned by MainNavigation.
  final DeviceMonitor monitor;

  const LiveMonitorScreen({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Monitoring',
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: monitor,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headingStyle = AppStyles.headingSmall.copyWith(color: cs.onSurface);
    final m = monitor;

    final children = <Widget>[
      StatusIndicator.fromMonitor(m),
      const SizedBox(height: 24),
    ];

    // No usable device: say why, and stop. No sensor tiles to fake.
    if (m.phase != MonitorPhase.ready) {
      children.add(_phaseMessage(context));
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      );
    }

    final reading = m.reading;
    final fresh = m.readingIsFresh;

    // Values are shown only while the reading is current.
    String? fmt(double? v) => (fresh && v != null) ? v.toStringAsFixed(2) : null;
    final accelUnit = fresh ? reading?.accelUnit : null;
    final gyroUnit = fresh ? reading?.gyroUnit : null;

    if (m.dataError != null) {
      children.add(_notice(context, m.dataError!, Icons.error_outline));
      children.add(const SizedBox(height: 16));
    }

    if (reading == null) {
      children.add(_notice(
        context,
        'This wearable hasn’t published any sensor readings.',
        Icons.sensors_off,
      ));
      children.add(const SizedBox(height: 16));
    } else if (!fresh) {
      children.add(_notice(
        context,
        'Readings are out of date. Last sensor update '
        '${DateTimeHelper.timeAgo(reading.timestamp, now: m.serverNow)}. '
        'Current values aren’t available.',
        Icons.sync_problem,
      ));
      children.add(const SizedBox(height: 16));
    }

    children.addAll([
      _sectionTitle('Accelerometer', headingStyle),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: SensorTile(
              title: 'X-Axis',
              value: fmt(reading?.accelX),
              unit: accelUnit,
              icon: Icons.sensors,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SensorTile(
              title: 'Y-Axis',
              value: fmt(reading?.accelY),
              unit: accelUnit,
              icon: Icons.sensors,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SensorTile(
              title: 'Z-Axis',
              value: fmt(reading?.accelZ),
              unit: accelUnit,
              icon: Icons.sensors,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _sectionTitle('Gyroscope', headingStyle),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: SensorTile(
              title: 'X-Rotation',
              value: fmt(reading?.gyroX),
              unit: gyroUnit,
              icon: Icons.rotate_right,
              color: AppColors.accentPurple,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SensorTile(
              title: 'Y-Rotation',
              value: fmt(reading?.gyroY),
              unit: gyroUnit,
              icon: Icons.rotate_right,
              color: AppColors.accentPurple,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SensorTile(
              title: 'Z-Rotation',
              value: fmt(reading?.gyroZ),
              unit: gyroUnit,
              icon: Icons.rotate_right,
              color: AppColors.accentPurple,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _sectionTitle('System Information', headingStyle),
      const SizedBox(height: 10),
      _systemInfo(context),
    ]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _phaseMessage(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = monitor;

    switch (m.phase) {
      case MonitorPhase.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        );
      case MonitorPhase.error:
        return Column(
          children: [
            Text(
              m.errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: m.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        );
      case MonitorPhase.noDevice:
      case MonitorPhase.ready:
        return Text(
          'Sensor readings will appear here once a wearable is linked and '
          'sending data.',
          textAlign: TextAlign.center,
          style: AppStyles.bodyMedium.copyWith(
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        );
    }
  }

  Widget _systemInfo(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = monitor;
    final reading = m.reading;
    final fresh = m.readingIsFresh;
    final connection = m.connection;
    final monitoring = m.status.monitoringActive;
    final battery = m.status.batteryPercent;

    final bodyStyle = AppStyles.bodyMedium.copyWith(color: cs.onSurface);
    final valueStyle = AppStyles.bodyMedium.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w600,
    );

    Widget row(IconData icon, Color iconColor, String label, String value,
        {Color? valueColor}) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: bodyStyle),
        trailing: Text(
          value,
          style: valueStyle.copyWith(color: valueColor ?? cs.onSurface),
        ),
      );
    }

    final rows = <Widget>[
      row(
        connectionIcon(connection),
        connectionColor(connection),
        'Device connection',
        connectionLabel(connection),
        valueColor: connectionColor(connection),
      ),
      row(
        Icons.shield_outlined,
        AppColors.primary,
        'Monitoring',
        monitoring == null ? 'Not reported' : (monitoring ? 'Active' : 'Paused'),
      ),
      row(
        Icons.psychology_outlined,
        AppColors.primary,
        'Fall detection result',
        fresh && reading != null
            ? predictionLabel(reading.prediction)
            : 'No current data',
      ),
      row(
        Icons.access_time,
        AppColors.warning,
        'Last sensor update',
        reading?.timestamp == null
            ? 'None'
            : DateTimeHelper.timeAgo(reading!.timestamp, now: m.serverNow),
      ),
      row(
        Icons.favorite_border,
        AppColors.warning,
        'Last heartbeat',
        m.status.lastHeartbeat == null
            ? 'None'
            : DateTimeHelper.timeAgo(m.status.lastHeartbeat, now: m.serverNow),
      ),
      if (battery != null)
        row(Icons.battery_std, AppColors.success, 'Battery', '$battery%'),
      if (m.deviceId != null)
        row(Icons.memory, AppColors.textLight, 'Device ID', m.deviceId!),
    ];

    final spaced = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) spaced.add(const Divider(height: 1));
      spaced.add(rows[i]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: spaced),
    );
  }

  Widget _notice(BuildContext context, String message, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String title, TextStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: style),
    );
  }
}