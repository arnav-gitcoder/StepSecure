// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Alerts",
          style: AppStyles.headingSmall,
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AlertCard(
            title: "Fall Detected",
            description: "Immediate assistance may be required.",
            time: "Today • 10:42 AM",
            icon: Icons.warning_rounded,
            color: AppColors.danger,
          ),

          SizedBox(height: 12),

          AlertCard(
            title: "Pre-Fall Warning",
            description: "Unstable movement detected.",
            time: "Today • 09:18 AM",
            icon: Icons.error_outline,
            color: AppColors.warning,
          ),

          SizedBox(height: 12),

          AlertCard(
            title: "Device Reconnected",
            description: "ESP32 connection restored.",
            time: "Yesterday • 08:51 PM",
            icon: Icons.wifi,
            color: AppColors.success,
          ),

          SizedBox(height: 12),

          AlertCard(
            title: "Low Battery",
            description: "Wearable device battery below 20%.",
            time: "Yesterday • 06:15 PM",
            icon: Icons.battery_alert,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;

  const AlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.cardTitle,
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: AppStyles.bodyMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  time,
                  style: AppStyles.cardSubtitle,
                ),
              ],
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'view',
                child: Text('View Details'),
              ),
              PopupMenuItem(
                value: 'dismiss',
                child: Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}