// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool vibrationEnabled = true;
  bool darkModeEnabled = themeNotifier.value == ThemeMode.dark;
  bool emergencyAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Text styles kept from AppStyles for size/weight, color overridden
    // per-theme so text stays readable in both light and dark mode.
    final titleStyle = AppStyles.cardTitle.copyWith(
      color: colorScheme.onSurface,
    );
    final bodyStyle = AppStyles.bodyMedium.copyWith(
      color: colorScheme.onSurface,
    );
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final headingStyle = AppStyles.headingSmall.copyWith(
      color: theme.appBarTheme.foregroundColor,
    );

    return Scaffold(
      // No hardcoded AppColors.background here — Scaffold already
      // inherits scaffoldBackgroundColor from the active theme in main.dart.
      appBar: AppBar(
        title: Text("Settings", style: headingStyle),
        // backgroundColor/foregroundColor removed — inherits from
        // appBarTheme (light/dark) defined in main.dart.
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Arnav Srivastava", style: titleStyle),
                    const SizedBox(height: 4),
                    Text("Caregiver Account", style: subtitleStyle),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text("Preferences", style: titleStyle),

          const SizedBox(height: 12),

          Card(
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text("Push Notifications", style: bodyStyle),
                  subtitle: Text(
                    "Receive fall detection alerts",
                    style: subtitleStyle,
                  ),
                  secondary: const Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                  ),
                  value: notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),

                SwitchListTile(
                  title: Text("Emergency Alerts", style: bodyStyle),
                  subtitle: Text(
                    "High-priority fall notifications",
                    style: subtitleStyle,
                  ),
                  secondary: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  value: emergencyAlertsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      emergencyAlertsEnabled = value;
                    });
                  },
                ),

                SwitchListTile(
                  title: Text("Vibration", style: bodyStyle),
                  subtitle: Text(
                    "Vibrate on notifications",
                    style: subtitleStyle,
                  ),
                  secondary: const Icon(
                    Icons.vibration,
                    color: AppColors.success,
                  ),
                  value: vibrationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      vibrationEnabled = value;
                    });
                  },
                ),

                SwitchListTile(
                  title: Text("Dark Mode", style: bodyStyle),
                  subtitle: Text("Enable dark theme", style: subtitleStyle),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  value: darkModeEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      darkModeEnabled = value;
                    });

                    themeNotifier.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text("Application", style: titleStyle),

          const SizedBox(height: 12),

          Card(
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  title: Text("About StepSecure", style: bodyStyle),
                  subtitle: Text("Version 1.0.0", style: subtitleStyle),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: () {},
                ),

                Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.1)),

                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.primary,
                  ),
                  title: Text("Help & Support", style: bodyStyle),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: () {},
                ),

                Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.1)),

                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text("Privacy Policy", style: bodyStyle),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout", style: AppStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}