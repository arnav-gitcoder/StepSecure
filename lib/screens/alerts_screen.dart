import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/widgets/alert_card.dart';

class _Alert {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;

  const _Alert({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<_Alert> _alerts = const [
    _Alert(
      title: "Fall Detected",
      description: "Immediate assistance may be required.",
      time: "Today • 10:42 AM",
      icon: Icons.warning_rounded,
      color: AppColors.danger,
    ),
    _Alert(
      title: "Pre-Fall Warning",
      description: "Unstable movement detected.",
      time: "Today • 09:18 AM",
      icon: Icons.error_outline,
      color: AppColors.warning,
    ),
    _Alert(
      title: "Device Reconnected",
      description: "ESP32 connection restored.",
      time: "Yesterday • 08:51 PM",
      icon: Icons.wifi,
      color: AppColors.success,
    ),
    _Alert(
      title: "Low Battery",
      description: "Wearable device battery below 20%.",
      time: "Yesterday • 06:15 PM",
      icon: Icons.battery_alert,
      color: AppColors.warning,
    ),
  ].toList();

  void _handleMenuAction(int index, String value) {
    final alert = _alerts[index];

    if (value == 'dismiss') {
      setState(() => _alerts.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${alert.title} dismissed')),
      );
    } else if (value == 'view') {
      _showDetail(alert);
    }
  }

  void _showDetail(_Alert alert) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text(
          alert.title,
          style: AppStyles.cardTitle.copyWith(color: cs.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.description,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              alert.time,
              style: AppStyles.cardSubtitle.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      // backgroundColor removed — Scaffold inherits scaffoldBackgroundColor
      // from the active theme (light/dark) set in main.dart.
      appBar: AppBar(
        title: Text(
          "Alerts",
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        // backgroundColor/foregroundColor removed — inherits appBarTheme.
        elevation: 0,
      ),
      body: _alerts.isEmpty
          ? Center(
              child: Text(
                "No alerts",
                style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return AlertCard(
                  title: alert.title,
                  description: alert.description,
                  time: alert.time,
                  icon: alert.icon,
                  color: alert.color,
                  onTap: () => _showDetail(alert),
                  onMenuSelected: (value) => _handleMenuAction(index, value),
                );
              },
            ),
    );
  }
}