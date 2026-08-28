import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/widgets/sensor_tile.dart';

class LiveMonitorScreen extends StatelessWidget {
  const LiveMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headingStyle = AppStyles.headingSmall.copyWith(
      color: cs.onSurface,
    );
    final bodyStyle = AppStyles.bodyMedium.copyWith(color: cs.onSurface);
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: cs.onSurface.withValues(alpha: 0.6),
    );

    return Scaffold(
      // backgroundColor removed — inherits scaffoldBackgroundColor.
      appBar: AppBar(
        title: Text(
          'Live Monitoring',
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card — fixed colored banner, same in both themes.
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

            _buildSectionTitle("Accelerometer", headingStyle),

            const SizedBox(height: 10),

            Row(
              children: const [
                Expanded(
                  child: SensorTile(
                    title: "X-Axis",
                    value: "0.23 g",
                    icon: Icons.sensors,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    title: "Y-Axis",
                    value: "-0.15 g",
                    icon: Icons.sensors,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    title: "Z-Axis",
                    value: "0.98 g",
                    icon: Icons.sensors,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("Gyroscope", headingStyle),

            const SizedBox(height: 10),

            Row(
              children: const [
                Expanded(
                  child: SensorTile(
                    title: "X-Rotation",
                    value: "1.42 °/s",
                    icon: Icons.rotate_right,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    title: "Y-Rotation",
                    value: "0.67 °/s",
                    icon: Icons.rotate_right,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SensorTile(
                    title: "Z-Rotation",
                    value: "0.89 °/s",
                    icon: Icons.rotate_right,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("System Information", headingStyle),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.wifi,
                      color: AppColors.success,
                    ),
                    title: Text("Device Connection", style: bodyStyle),
                    trailing: const Text(
                      "Connected",
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.memory,
                      color: AppColors.primary,
                    ),
                    title: Text("ML Model Status", style: bodyStyle),
                    trailing: const Text(
                      "Active",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.warning,
                    ),
                    title: Text("Last Update", style: bodyStyle),
                    trailing: Text("Just Now", style: subtitleStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSectionTitle(String title, TextStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: style),
    );
  }
}