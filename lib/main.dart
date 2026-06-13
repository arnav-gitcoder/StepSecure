import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_monitor_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';

import 'constants/colors.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

void main() {
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

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,

            scaffoldBackgroundColor: AppColors.background,

            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.primary,
              surface: AppColors.cardBackground,
              error: AppColors.danger,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
            ),

            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppColors.cardBackground,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,

            scaffoldBackgroundColor: const Color(0xFF111827),

            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.primary,
              surface: Color(0xFF1F2937),
              error: AppColors.danger,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppColors.background,
              indicatorColor: AppColors.primary.withValues(alpha: 0.25),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

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

  final List<Widget> screens = const [
    HomeScreen(),
    LiveMonitorScreen(),
    AlertsScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
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