import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/live_monitor_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/contacts_screen.dart';

/// Route name constants. Never hardcode route strings elsewhere.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String liveMonitor = '/live-monitor';
  static const String alerts = '/alerts';
  static const String contacts = '/contacts';

  /// Single source of truth for route -> screen mapping.
  /// Used by MaterialApp.onGenerateRoute.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _build(const SplashScreen(), settings);

      case login:
        return _build(const LoginScreen(), settings);

      case home:
        return _build(const HomeScreen(), settings);

      case liveMonitor:
        return _build(const LiveMonitorScreen(), settings);

      case alerts:
        return _build(const AlertsScreen(), settings);

      case contacts:
        return _build(const ContactsScreen(), settings);

      default:
        return _build(
          Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('No route defined for "${settings.name}"'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _build(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => screen,
      settings: settings,
    );
  }

  // Navigation helpers — use these instead of raw Navigator calls
  // so route names stay consistent app-wide.

  static Future<void> goToLogin(BuildContext context) {
    return Navigator.pushReplacementNamed(context, login);
  }

  static Future<void> goToHome(BuildContext context) {
    return Navigator.pushReplacementNamed(context, home);
  }

  static Future<void> goToLiveMonitor(BuildContext context) {
    return Navigator.pushNamed(context, liveMonitor);
  }

  static Future<void> goToAlerts(BuildContext context, {Object? arguments}) {
    return Navigator.pushNamed(context, alerts, arguments: arguments);
  }

  static Future<void> goToContacts(BuildContext context) {
    return Navigator.pushNamed(context, contacts);
  }

  static void logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }
}