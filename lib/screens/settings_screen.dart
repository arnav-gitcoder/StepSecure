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
  bool darkModeEnabled = false;
  bool emergencyAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Settings", style: AppStyles.headingSmall),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Arnav Srivastava", style: AppStyles.cardTitle),
                    SizedBox(height: 4),
                    Text("Caregiver Account", style: AppStyles.cardSubtitle),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("Preferences", style: AppStyles.cardTitle),

          const SizedBox(height: 12),

          Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    "Push Notifications",
                    style: AppStyles.bodyMedium,
                  ),
                  subtitle: const Text(
                    "Receive fall detection alerts",
                    style: AppStyles.cardSubtitle,
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
                  title: const Text(
                    "Emergency Alerts",
                    style: AppStyles.bodyMedium,
                  ),
                  subtitle: const Text(
                    "High-priority fall notifications",
                    style: AppStyles.cardSubtitle,
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
                  title: const Text("Vibration", style: AppStyles.bodyMedium),
                  subtitle: const Text(
                    "Vibrate on notifications",
                    style: AppStyles.cardSubtitle,
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
                  title: const Text("Dark Mode", style: AppStyles.bodyMedium),
                  subtitle: const Text(
                    "Enable dark theme",
                    style: AppStyles.cardSubtitle,
                  ),
                  secondary: const Icon(
                    Icons.dark_mode,
                    color: AppColors.textSecondary,
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

          const Text("Application", style: AppStyles.cardTitle),

          const SizedBox(height: 12),

          Card(
            color: AppColors.cardBackground,
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
                  title: const Text(
                    "About StepSecure",
                    style: AppStyles.bodyMedium,
                  ),
                  subtitle: const Text(
                    "Version 1.0.0",
                    style: AppStyles.cardSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    "Help & Support",
                    style: AppStyles.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    "Privacy Policy",
                    style: AppStyles.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
