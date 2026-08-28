import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const String _themePrefsKey = 'theme_mode';

// Default is dark mode, per product decision, but this gets
// overwritten below by whatever was last saved to disk.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

/// Reads the saved theme choice and updates themeNotifier before first
/// frame, so the app doesn't flash dark-then-light on startup.
Future<void> _loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_themePrefsKey);
  if (saved == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (saved == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }
  // If nothing saved yet (first-ever launch), keep the ThemeMode.dark
  // default above.
}

/// Call this from the Settings toggle instead of setting
/// themeNotifier.value directly, so the choice survives a restart.
Future<void> setThemeMode(ThemeMode mode) async {
  themeNotifier.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _themePrefsKey,
    mode == ThemeMode.dark ? 'dark' : 'light',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _loadSavedTheme();
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