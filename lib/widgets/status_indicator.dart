import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/sensor_data_model.dart';
import '../services/device_monitor.dart';
import '../utils/date_time_helper.dart';

enum StatusLevel { ok, warning, danger, neutral }

String connectionLabel(DeviceConnection c) {
  switch (c) {
    case DeviceConnection.connected:
      return 'Connected';
    case DeviceConnection.stale:
      return 'No recent data';
    case DeviceConnection.disconnected:
      return 'Offline';
    case DeviceConnection.unknown:
      return 'Status unknown';
  }
}

IconData connectionIcon(DeviceConnection c) {
  switch (c) {
    case DeviceConnection.connected:
      return Icons.wifi;
    case DeviceConnection.stale:
      return Icons.sync_problem;
    case DeviceConnection.disconnected:
      return Icons.wifi_off;
    case DeviceConnection.unknown:
      return Icons.help_outline;
  }
}

Color connectionColor(DeviceConnection c) {
  switch (c) {
    case DeviceConnection.connected:
      return AppColors.connected;
    case DeviceConnection.stale:
      return AppColors.warning;
    case DeviceConnection.disconnected:
      return AppColors.disconnected;
    case DeviceConnection.unknown:
      return AppColors.textLight;
  }
}

String predictionLabel(FallPrediction p) {
  switch (p) {
    case FallPrediction.normal:
      return 'Normal';
    case FallPrediction.warning:
      return 'Warning';
    case FallPrediction.fall:
      return 'Fall detected';
    case FallPrediction.unknown:
      return 'Unknown';
  }
}

/// Large status banner. Every state has an icon AND text, so meaning never
/// depends on colour alone.
///
/// Use [StatusIndicator.fromMonitor] to describe the wearable. It only says
/// "monitoring active" when the device is genuinely connected and reports
/// it, and it never says "normal" just because nothing has gone wrong yet.
class StatusIndicator extends StatelessWidget {
  final StatusLevel level;
  final IconData icon;
  final String title;
  final String? detail;

  const StatusIndicator({
    super.key,
    required this.level,
    required this.icon,
    required this.title,
    this.detail,
  });

  factory StatusIndicator.fromMonitor(
    DeviceMonitor m, {
    int unacknowledgedFalls = 0,
  }) {
    // 1. A fall always outranks everything else.
    if (unacknowledgedFalls > 0) {
      return StatusIndicator(
        level: StatusLevel.danger,
        icon: Icons.warning_rounded,
        title: 'FALL ALERT',
        detail: unacknowledgedFalls == 1
            ? '1 fall alert needs attention.'
            : '$unacknowledgedFalls fall alerts need attention.',
      );
    }
    if (m.readingIsFresh && m.reading?.prediction == FallPrediction.fall) {
      return const StatusIndicator(
        level: StatusLevel.danger,
        icon: Icons.warning_rounded,
        title: 'FALL DETECTED',
        detail: 'The wearable has just reported a fall.',
      );
    }

    // 2. Otherwise describe what we actually know about the device.
    switch (m.phase) {
      case MonitorPhase.loading:
        return const StatusIndicator(
          level: StatusLevel.neutral,
          icon: Icons.sync,
          title: 'CHECKING WEARABLE',
          detail: 'Looking for your wearable’s status…',
        );
      case MonitorPhase.error:
        return StatusIndicator(
          level: StatusLevel.warning,
          icon: Icons.error_outline,
          title: 'STATUS UNAVAILABLE',
          detail: m.errorMessage,
        );
      case MonitorPhase.noDevice:
        return const StatusIndicator(
          level: StatusLevel.neutral,
          icon: Icons.watch_outlined,
          title: 'NO WEARABLE LINKED',
          detail: 'Once a wearable is linked to this account, '
              'its status will appear here.',
        );
      case MonitorPhase.ready:
        break;
    }

    switch (m.connection) {
      case DeviceConnection.disconnected:
        return const StatusIndicator(
          level: StatusLevel.warning,
          icon: Icons.wifi_off,
          title: 'WEARABLE OFFLINE',
          detail: 'Falls can’t be reported until it reconnects.',
        );
      case DeviceConnection.stale:
        return StatusIndicator(
          level: StatusLevel.warning,
          icon: Icons.sync_problem,
          title: 'NO RECENT DATA',
          detail: 'Last heard from it '
              '${DateTimeHelper.timeAgo(m.lastCommunication, now: m.serverNow)}. '
              'Falls may not be reported.',
        );
      case DeviceConnection.unknown:
        return const StatusIndicator(
          level: StatusLevel.neutral,
          icon: Icons.help_outline,
          title: 'STATUS UNKNOWN',
          detail: 'The wearable hasn’t reported its status yet.',
        );
      case DeviceConnection.connected:
        final monitoring = m.status.monitoringActive;
        if (monitoring == false) {
          return const StatusIndicator(
            level: StatusLevel.warning,
            icon: Icons.pause_circle_outline,
            title: 'MONITORING PAUSED',
            detail: 'Fall detection is turned off on the wearable.',
          );
        }
        if (monitoring == true) {
          return const StatusIndicator(
            level: StatusLevel.ok,
            icon: Icons.health_and_safety,
            title: 'MONITORING ACTIVE',
            detail: 'The wearable is connected and watching for falls.',
          );
        }
        return const StatusIndicator(
          level: StatusLevel.neutral,
          icon: Icons.check_circle_outline,
          title: 'WEARABLE CONNECTED',
          detail: 'It hasn’t reported whether monitoring is active.',
        );
    }
  }

  Color _accent(ColorScheme cs) {
    switch (level) {
      case StatusLevel.ok:
        return AppColors.success;
      case StatusLevel.warning:
        return AppColors.warning;
      case StatusLevel.danger:
        return AppColors.fallDetected;
      case StatusLevel.neutral:
        return cs.onSurface.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accent(cs);
    final isDanger = level == StatusLevel.danger;

    // Danger is a solid block with white text; the rest are tinted so text
    // stays readable on both themes (white on the light green was not).
    final background = isDanger ? accent : accent.withValues(alpha: 0.12);
    final foreground = isDanger ? Colors.white : cs.onSurface;
    final iconColor = isDanger ? Colors.white : accent;

    final detailText = detail;

    return Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: detailText == null || detailText.isEmpty
          ? title
          : '$title. $detailText',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: isDanger
              ? null
              : Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 56),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            if (detailText != null && detailText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detailText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.85),
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}