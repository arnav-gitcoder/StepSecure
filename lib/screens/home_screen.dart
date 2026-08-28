import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/widgets/dashboard_card.dart';

class HomeScreen extends StatelessWidget {
  /// Called with the target bottom-nav tab index when a quick action
  /// maps to an existing tab (e.g. Contacts). Null when this screen is
  /// used outside MainNavigation.
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Text styles kept from AppStyles for size/weight, color made
    // theme-aware so they stay legible in both light and dark mode.
    final titleStyle = AppStyles.cardTitle.copyWith(color: cs.onSurface);
    final bodyStyle = AppStyles.bodyMedium.copyWith(color: cs.onSurface);
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: cs.onSurface.withValues(alpha: 0.6),
    );

    return Scaffold(
      // backgroundColor removed — inherits scaffoldBackgroundColor.
      appBar: AppBar(
        title: Text(
          "StepSecure",
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
            // Device Status
            DashboardCard(
              title: "Device Status",
              subtitle: "ESP32 Connected",
              icon: Icons.wifi,
              iconColor: AppColors.success,
            ),

            const SizedBox(height: 20),

            // Main Status Card — status banners keep a fixed colored
            // background with white text in both themes intentionally,
            // so this stays hardcoded.
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
                    "No Emergency Detected",
                    style: TextStyle(
                      color: Colors.white,
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
                    cardColor: cs.surface,
                    valueColor: cs.onSurface,
                    subtitleStyle: subtitleStyle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: "Warnings",
                    value: "12",
                    icon: Icons.notifications_active,
                    color: AppColors.warning,
                    cardColor: cs.surface,
                    valueColor: cs.onSurface,
                    subtitleStyle: subtitleStyle,
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
                          tileColor: theme.scaffoldBackgroundColor,
                          bodyStyle: bodyStyle,
                          // TODO: trigger emergency SOS flow.
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.location_on,
                          label: "Location",
                          color: AppColors.primary,
                          tileColor: theme.scaffoldBackgroundColor,
                          bodyStyle: bodyStyle,
                          // TODO: open live location view.
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
                          tileColor: theme.scaffoldBackgroundColor,
                          bodyStyle: bodyStyle,
                          // Contacts is tab index 3 in MainNavigation.
                          onTap: () => onNavigateToTab?.call(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.shield,
                          label: "Safety Tips",
                          color: AppColors.warning,
                          tileColor: theme.scaffoldBackgroundColor,
                          bodyStyle: bodyStyle,
                          // TODO: wire to a SafetyTipsScreen once it exists.
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
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    title: Text("Normal Activity", style: bodyStyle),
                    subtitle: Text("10:42 AM", style: subtitleStyle),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                    ),
                    title: Text("Location Updated", style: bodyStyle),
                    subtitle: Text("10:35 AM", style: subtitleStyle),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    title: Text("Warning Detected", style: bodyStyle),
                    subtitle: Text("10:22 AM", style: subtitleStyle),
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
    required Color tileColor,
    required TextStyle bodyStyle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: bodyStyle),
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
    required Color cardColor,
    required Color valueColor,
    required TextStyle subtitleStyle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 50),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: subtitleStyle),
        ],
      ),
    );
  }
}