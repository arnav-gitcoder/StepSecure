import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';

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
            // Device Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.textPrimary,
                    child: Icon(Icons.wifi, color: AppColors.success),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Device Status", style: AppStyles.cardSubtitle),
                        SizedBox(height: 4),
                        Text(
                          "Connected",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    "Patient is Safe",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Section
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
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Quick Access", style: AppStyles.cardTitle),
      const SizedBox(height: 15),

      Row(
        children: [
          Expanded(
            child: _buildQuickAction(
              icon: Icons.sos,
              label: "SOS",
              color: AppColors.danger,
              onTap: () {
                // TODO: Emergency SOS
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickAction(
              icon: Icons.location_on,
              label: "Location",
              color: AppColors.primary,
              onTap: () {
                // TODO: Share Location
              },
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
              onTap: () {
                // Navigate to Contacts Screen
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickAction(
              icon: Icons.shield,
              label: "Safety Tips",
              color: AppColors.warning,
              onTap: () {
                // TODO: Safety Tips Screen
              },
            ),
          ),
        ],
      ),
    ],
  ),
),

            const SizedBox(height: 20),

            // Recent Activity
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Recent Activity", style: AppStyles.cardTitle),
                  SizedBox(height: 15),
                  ListTile(
                    leading: Icon(
                      Icons.directions_walk,
                      color: AppColors.primary,
                    ),
                    title: Text("Walking", style: AppStyles.bodyMedium),
                    subtitle: Text("10:42 AM", style: AppStyles.cardSubtitle),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.accessibility_new,
                      color: AppColors.primary,
                    ),
                    title: Text("Standing", style: AppStyles.bodyMedium),
                    subtitle: Text("10:35 AM", style: AppStyles.cardSubtitle),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.event_seat, color: AppColors.primary),
                    title: Text("Sitting", style: AppStyles.bodyMedium),
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
          Icon(icon, color: AppColors.icon, size: 50),
          const SizedBox(height: 10),
          Text(value, style: AppStyles.headingMedium),
          const SizedBox(height: 4),
          Text(title, style: AppStyles.cardSubtitle),
        ],
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
          Text(
            label,
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
}
