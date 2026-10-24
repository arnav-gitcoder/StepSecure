import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/models/alert_model.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/services/firestore_service.dart';
import 'package:stepsecure_app/utils/alert_style.dart';
import 'package:stepsecure_app/utils/data_error_helper.dart';
import 'package:stepsecure_app/utils/date_time_helper.dart';
import 'package:stepsecure_app/widgets/alert_card.dart';

/// The caregiver's alert history, newest first, straight from Firestore.
///
/// * Alerts are created by the backend, never by this screen.
/// * "Acknowledge" marks an alert as handled; nothing is ever deleted.
/// * Notification / escalation status is shown exactly as the backend
///   reports it ("not reported" if it never did).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const int _pageSize = FirestoreService.defaultAlertPageSize;

  final FirestoreService _firestore = FirestoreService();
  late Stream<List<AlertModel>> _stream;

  /// Older pages loaded on demand ("Load older alerts"). The newest
  /// [_pageSize] alerts come from the live stream.
  final List<AlertModel> _older = [];
  bool _loadingMore = false;
  bool _noMoreOlder = false;

  /// Alert ids with an acknowledge request in flight (blocks double taps).
  final Set<String> _acknowledging = {};

  String? get _uid => AuthService.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _stream = _open();
  }

  Stream<List<AlertModel>> _open() {
    try {
      final uid = _uid;
      if (uid == null) return const Stream<List<AlertModel>>.empty();
      return _firestore.alertsStream(uid);
    } catch (e) {
      return Stream<List<AlertModel>>.error(e);
    }
  }

  void _reload() {
    setState(() {
      _older.clear();
      _noMoreOlder = false;
      _stream = _open();
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Live alerts followed by any older pages, without duplicates.
  List<AlertModel> _combine(List<AlertModel> live) {
    final liveIds = live.map((a) => a.id).toSet();
    return [...live, ..._older.where((a) => !liveIds.contains(a.id))];
  }

  Future<void> _loadOlder(List<AlertModel> current) async {
    final uid = _uid;
    final oldest = current.isEmpty ? null : current.last.timestamp;
    if (uid == null || oldest == null || _loadingMore) return;

    setState(() => _loadingMore = true);
    try {
      final page = await _firestore.fetchAlertsBefore(uid, oldest);
      if (!mounted) return;
      setState(() {
        _older.addAll(page);
        if (page.length < _pageSize) _noMoreOlder = true;
      });
    } catch (e) {
      if (!mounted) return;
      _snack(DataErrorHelper.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _acknowledge(AlertModel alert) async {
    final uid = _uid;
    if (uid == null || _acknowledging.contains(alert.id)) return;

    setState(() => _acknowledging.add(alert.id));
    try {
      // Needs a connection on purpose: offline this fails, so we never
      // claim an alert was acknowledged when it wasn't.
      final found = await _firestore.acknowledgeAlert(uid, alert.id);
      if (!mounted) return;

      if (!found) {
        _snack('That alert no longer exists.');
      } else {
        // Older pages aren't covered by the live stream, so update them here.
        setState(() {
          for (var i = 0; i < _older.length; i++) {
            if (_older[i].id == alert.id && _older[i].needsAttention) {
              _older[i] = _older[i].copyWith(
                status: AlertStatus.acknowledged,
                acknowledgedAt: DateTime.now(),
              );
            }
          }
        });
        _snack('Alert acknowledged.');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(
        "Couldn't acknowledge the alert. ${DataErrorHelper.friendlyMessage(e)}",
      );
    } finally {
      if (mounted) setState(() => _acknowledging.remove(alert.id));
    }
  }

  void _showDetail(AlertModel alert) {
    final cs = Theme.of(context).colorScheme;
    final style = alertStyleFor(alert);

    String statusText;
    switch (alert.status) {
      case AlertStatus.pending:
        statusText = 'Needs attention';
        break;
      case AlertStatus.acknowledged:
        statusText = alert.acknowledgedAt == null
            ? 'Acknowledged'
            : 'Acknowledged ${DateTimeHelper.timeAgo(alert.acknowledgedAt)}';
        break;
      case AlertStatus.resolved:
        statusText = 'Resolved';
        break;
    }

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
          ],
        ),
      );
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Icon(style.icon, color: style.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alert.displayTitle,
                style: AppStyles.cardTitle.copyWith(color: cs.onSurface),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alert.description.isNotEmpty) row('Details', alert.description),
              row('When', DateTimeHelper.formatDateTime(alert.timestamp)),
              row('Status', statusText),
              row('Notification', notificationLabel(alert)),
              row('Emergency contacts', escalationLabel(alert)),
              row('Event type', alert.eventType ?? 'Not reported'),
              row('Device', alert.deviceId ?? 'Not reported'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (alert.needsAttention)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _acknowledge(alert);
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts',
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return _message(
              context,
              icon: Icons.error_outline,
              text: DataErrorHelper.friendlyMessage(snap.error!),
              action: TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final live = snap.data!;
          final alerts = _combine(live);

          if (alerts.isEmpty) {
            return _message(
              context,
              icon: Icons.notifications_none,
              text: 'No alerts yet. Alerts from your wearable will appear '
                  'here.',
            );
          }

          final canLoadMore =
              (live.length >= _pageSize || _older.isNotEmpty) && !_noMoreOlder;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length + (canLoadMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == alerts.length) {
                return Center(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        )
                      : TextButton(
                          onPressed: () => _loadOlder(alerts),
                          child: const Text('Load older alerts'),
                        ),
                );
              }

              final alert = alerts[index];
              final style = alertStyleFor(alert);
              final when = alert.timestamp == null
                  ? 'Unknown time'
                  : '${DateTimeHelper.timeAgo(alert.timestamp)} • '
                      '${DateTimeHelper.formatDateTime(alert.timestamp)}';

              return AlertCard(
                title: alert.displayTitle,
                description: alert.description,
                time: when,
                icon: style.icon,
                color: style.color,
                isAcknowledged: alert.isAcknowledged,
                statusLabel:
                    alert.status == AlertStatus.resolved ? 'Resolved' : null,
                onTap: () => _showDetail(alert),
                onMenuSelected: (value) {
                  if (value == AlertCard.actionView) {
                    _showDetail(alert);
                  } else if (value == AlertCard.actionAcknowledge) {
                    _acknowledge(alert);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}