import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_monitor_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';

// Prefixed import: constants/colors.dart also defines a class named
// AppColors, which would clash with app_theme.dart's AppColors if both
// were imported unprefixed in the same file. main.dart only needs
// AppTheme here, so it's referenced as `apptheme.AppTheme`.
import 'config/app_theme.dart' as apptheme;

// Default is dark mode, per product decision. Toggle in Settings
// flips this via themeNotifier.value.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StepSecureApp());
}

class StepSecureApp extends StatelessWidget {
  const StepSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'StepSecure',
          debugShowCheckedModeBanner: false,

          themeMode: currentTheme,
          theme: apptheme.AppTheme.lightTheme,
          darkTheme: apptheme.AppTheme.darkTheme,

          home: const SplashScreen(),
        );
      },
    );
  }
}

/// Main Navigation Screen
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToTab: _goToTab),
      const LiveMonitorScreen(),
      const AlertsScreen(),
      const ContactsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}