import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';

class LiveMonitorScreen extends StatelessWidget {
  const LiveMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Live Monitoring',
          style: AppStyles.headingSmall,
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "NORMAL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No Fall Risk Detected",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Accelerometer"),

            const SizedBox(height: 10),

            _sensorGroupCard(
              title: "Accelerometer Data",
              icon: Icons.sensors,
              iconColor: AppColors.primary,
              values: const [
                ["X-Axis", "0.23 g"],
                ["Y-Axis", "-0.15 g"],
                ["Z-Axis", "0.98 g"],
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Gyroscope"),

            const SizedBox(height: 10),

            _sensorGroupCard(
              title: "Gyroscope Data",
              icon: Icons.rotate_right,
              iconColor: Colors.purple,
              values: const [
                ["X-Rotation", "1.42 °/s"],
                ["Y-Rotation", "0.67 °/s"],
                ["Z-Rotation", "0.89 °/s"],
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("System Information"),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.wifi,
                      color: AppColors.success,
                    ),
                    title: Text(
                      "Device Connection",
                      style: AppStyles.bodyMedium,
                    ),
                    trailing: Text(
                      "Connected",
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.memory,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      "ML Model Status",
                      style: AppStyles.bodyMedium,
                    ),
                    trailing: Text(
                      "Active",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      "Last Update",
                      style: AppStyles.bodyMedium,
                    ),
                    trailing: Text(
                      "Just Now",
                      style: AppStyles.cardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppStyles.headingSmall,
      ),
    );
  }

  static Widget _sensorGroupCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<List<String>> values,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppStyles.cardTitle,
              ),
            ],
          ),

          const SizedBox(height: 16),

          for (int i = 0; i < values.length; i++) ...[
            _sensorValueRow(
              values[i][0],
              values[i][1],
            ),
            if (i != values.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }

  static Widget _sensorValueRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodyMedium,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}