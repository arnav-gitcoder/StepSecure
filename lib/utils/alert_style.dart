import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/alert_model.dart';

/// Icon and colour for an alert, chosen from its `eventType`.
class AlertStyle {
  final IconData icon;
  final Color color;

  const AlertStyle(this.icon, this.color);
}

bool isFallAlert(AlertModel a) {
  final type = (a.eventType ?? '').toLowerCase();
  return type == 'fall_detected' || type == 'fall';
}

AlertStyle alertStyleFor(AlertModel a) {
  switch ((a.eventType ?? '').toLowerCase()) {
    case 'fall_detected':
    case 'fall':
      return const AlertStyle(Icons.warning_rounded, AppColors.fallDetected);
    case 'low_battery':
      return const AlertStyle(Icons.battery_alert, AppColors.warning);
    case 'device_offline':
      return const AlertStyle(Icons.wifi_off, AppColors.warning);
    case 'device_reconnected':
      return const AlertStyle(Icons.wifi, AppColors.success);
    default:
      return const AlertStyle(Icons.notifications_outlined, AppColors.primary);
  }
}

/// What we can honestly say about notification delivery. These come from the
/// backend; "unknown" means it never reported anything, so we claim nothing.
String notificationLabel(AlertModel a) {
  switch (a.notificationStatus) {
    case NotificationStatus.notSent:
      return 'Notification not sent';
    case NotificationStatus.pending:
      return 'Notification pending';
    case NotificationStatus.sent:
      return 'Notification sent';
    case NotificationStatus.failed:
      return 'Notification failed';
    case NotificationStatus.unknown:
      return 'Notification status not reported';
  }
}

String escalationLabel(AlertModel a) {
  switch (a.escalationStatus) {
    case EscalationStatus.none:
      return 'No emergency escalation';
    case EscalationStatus.pending:
      return 'Emergency contacts: pending';
    case EscalationStatus.contactsNotified:
      return 'Emergency contacts notified';
    case EscalationStatus.failed:
      return 'Emergency contact alert failed';
    case EscalationStatus.unknown:
      return 'Escalation status not reported';
  }
}