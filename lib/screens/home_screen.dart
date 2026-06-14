import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/widgets/dashboard_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("StepSecure", style: AppStyles.headingSmall),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Device Status
            DashboardCard(
              title: "Device Status",
              subtitle: "ESP32 Connected",
              icon: Icons.wifi,
              iconColor: AppColors.success,
            ),

            const SizedBox(height: 20),

            // Main Status Card
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
                    color: AppColors.textPrimary,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "NORMAL",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "No Emergency Detected",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Falls",
                    value: "3",
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: "Warnings",
                    value: "12",
                    icon: Icons.notifications_active,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Access
            DashboardCard(
              title: "Quick Access",
              icon: Icons.flash_on,
              iconColor: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.sos,
                          label: "SOS",
                          color: AppColors.danger,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.location_on,
                          label: "Location",
                          color: AppColors.primary,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.people,
                          label: "Contacts",
                          color: AppColors.success,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.shield,
                          label: "Safety Tips",
                          color: AppColors.warning,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Activity
            DashboardCard(
              title: "Recent Activity",
              icon: Icons.history,
              iconColor: AppColors.primary,
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.check_circle, color: AppColors.success),
                    title: Text("Normal Activity", style: AppStyles.bodyMedium),
                    subtitle: Text("10:42 AM", style: AppStyles.cardSubtitle),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(
                      "Location Updated",
                      style: AppStyles.bodyMedium,
                    ),
                    subtitle: Text("10:35 AM", style: AppStyles.cardSubtitle),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    title: Text(
                      "Warning Detected",
                      style: AppStyles.bodyMedium,
                    ),
                    subtitle: Text("10:22 AM", style: AppStyles.cardSubtitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: AppStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 50),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppStyles.cardSubtitle),
        ],
      ),
    );
  }
}
