import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/services/firestore_service.dart';
import '../main.dart';

/// Version shown in "About". Keep in step with `version:` in pubspec.yaml.
const String _appVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestore = FirestoreService();
  Stream<Map<String, dynamic>?>? _profile;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      try {
        _profile = _firestore.userProfileStream(uid);
      } catch (_) {
        _profile = null; // Fall back to the Auth account details only.
      }
    }
  }

  Future<void> _confirmLogout() async {
    if (_signingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to sign in again to see your alerts and wearable.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      // MainNavigation listens for the signed-out event and returns to the
      // login screen, so no navigation is needed here.
      await AuthService.instance.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't log out. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'StepSecure',
      applicationVersion: _appVersion,
      applicationIcon: const Icon(
        Icons.shield_outlined,
        color: AppColors.primary,
        size: 40,
      ),
      children: const [
        Text(
          'StepSecure shows fall alerts and status from your wearable. '
          'The wearable detects falls; this app only displays what it '
          'reports.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = AppStyles.cardTitle.copyWith(color: cs.onSurface);
    final bodyStyle = AppStyles.bodyMedium.copyWith(color: cs.onSurface);
    final subtitleStyle = AppStyles.cardSubtitle.copyWith(
      color: cs.onSurface.withValues(alpha: 0.7),
    );

    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: _profile,
            builder: (context, snap) {
              // Errors / no profile just mean fewer details, never a crash.
              final data = snap.data;
              final storedName = (data?['displayName'] as String?)?.trim();
              final authName = user?.displayName?.trim();
              final name = (storedName != null && storedName.isNotEmpty)
                  ? storedName
                  : (authName != null && authName.isNotEmpty)
                      ? authName
                      : 'Caregiver';
              final phone = (data?['phone'] as String?)?.trim();
              final email = user?.email;
              final verified = user?.emailVerified ?? false;

              return _profileCard(
                context,
                name: name,
                email: email,
                phone: (phone == null || phone.isEmpty) ? null : phone,
                verified: verified,
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
              );
            },
          ),

          const SizedBox(height: 20),
          Text('Appearance', style: titleStyle),
          const SizedBox(height: 12),

          Card(
            margin: EdgeInsets.zero,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return SwitchListTile(
                  title: Text('Dark Mode', style: bodyStyle),
                  subtitle: Text('Use the dark theme', style: subtitleStyle),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                  value: mode == ThemeMode.dark,
                  onChanged: (value) {
                    // Applies immediately; saving the choice is best-effort.
                    unawaited(
                      setThemeMode(value ? ThemeMode.dark : ThemeMode.light)
                          .catchError((_) {}),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Text('Notifications', style: titleStyle),
          const SizedBox(height: 12),

          // Push notifications are not built yet. Say so instead of showing
          // switches that do nothing.
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.warning,
              ),
              title: Text('Push notifications', style: bodyStyle),
              subtitle: Text(
                'Not set up yet. Fall alerts appear in the Alerts tab '
                'while the app is open.',
                style: subtitleStyle,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text('Application', style: titleStyle),
          const SizedBox(height: 12),

          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: AppColors.primary,
              ),
              title: Text('About StepSecure', style: bodyStyle),
              subtitle: Text('Version $_appVersion', style: subtitleStyle),
              trailing: Icon(
                Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              onTap: _showAbout,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _signingOut ? null : _confirmLogout,
              icon: _signingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Logout', style: AppStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
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

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String? email,
    required String? phone,
    required bool verified,
    required TextStyle titleStyle,
    required TextStyle subtitleStyle,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: titleStyle, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Caregiver account', style: subtitleStyle),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(email, style: subtitleStyle,
                      overflow: TextOverflow.ellipsis),
                ],
                if (phone != null) ...[
                  const SizedBox(height: 2),
                  Text(phone, style: subtitleStyle),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified ? Icons.verified_outlined : Icons.error_outline,
                      size: 16,
                      color: verified ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'Email verified' : 'Email not verified',
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}