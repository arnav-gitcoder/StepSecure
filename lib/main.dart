import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/device_monitor.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_monitor_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';

import 'config/app_theme.dart';

const String _themePrefsKey = 'theme_mode';

// Default is dark mode, per product decision, but this gets
// overwritten below by whatever was last saved to disk.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

/// Reads the saved theme choice and updates themeNotifier before first
/// frame, so the app doesn't flash dark-then-light on startup.
Future<void> _loadSavedTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themePrefsKey);
    if (saved == 'light') {
      themeNotifier.value = ThemeMode.light;
    } else if (saved == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    }
  } catch (_) {
    // Storage unavailable: keep the ThemeMode.dark default above rather than
    // failing to start the app over a cosmetic preference.
  }
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // The apps check avoids a duplicate-app error on retry / hot restart.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    runApp(StartupFailureApp(onRetry: main));
    return;
  }

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
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          home: const SplashScreen(),
        );
      },
    );
  }
}

/// Shown instead of a blank/red screen when Firebase can't start.
class StartupFailureApp extends StatelessWidget {
  final VoidCallback onRetry;

  const StartupFailureApp({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepSecure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _StartupFailureScreen(onRetry: onRetry),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupFailureScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  "StepSecure couldn't start",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  "Check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try again"),
                ),
              ],
            ),
          ),
        ),
      ),
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

  // Built once. With an IndexedStack the tabs keep their state when you
  // switch between them (before, each switch threw the screen away, so
  // added contacts and dismissed alerts were lost).
  late final List<Widget> _screens;

  // Shared wearable state for Home and Monitor. Created here and disposed
  // with this screen (e.g. on sign-out), so its listeners never outlive the
  // signed-in session.
  late final DeviceMonitor _monitor;

  StreamSubscription<Object?>? _authSub;

  @override
  void initState() {
    super.initState();

    _monitor = DeviceMonitor(
      uid: AuthService.instance.currentUser?.uid ?? '',
    );

    _screens = [
      HomeScreen(monitor: _monitor, onNavigateToTab: _goToTab),
      LiveMonitorScreen(monitor: _monitor),
      const AlertsScreen(),
      const ContactsScreen(),
      const SettingsScreen(),
    ];

    // This screen only exists while signed in, so a signed-out event means
    // the session ended (logout, expired or revoked account). Return to
    // login so no one keeps looking at the previous user's data.
    _authSub = AuthService.instance.authStateChanges.listen(
      (user) {
        if (user == null && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _monitor.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // On any tab but Home, Back returns to Home instead of closing the app.
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goToTab(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: _screens,
        ),

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
      ),
    );
  }
}