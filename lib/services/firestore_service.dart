import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alert_model.dart';
import '../models/emergency_contact.dart';

/// Firestore reads/writes for the caregiver profile, alerts and emergency
/// contacts, always scoped to one user: `users/{uid}` (profile),
/// `users/{uid}/alerts` and `users/{uid}/contacts`.
///
/// Alerts are created by the backend/ESP32 pipeline, not by the app. The app
/// reads them and acknowledges them. Alerts are never deleted from the app.
///
/// Stream errors (permission-denied, offline) are not swallowed; handle them
/// in the listener / `StreamBuilder.hasError` and show
/// `DataErrorHelper.friendlyMessage(error)`.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int defaultAlertPageSize = 50;

  String _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return value;
  }

  // ---------- PROFILE ----------

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) {
    return _db.collection('users').doc(_requireNonEmpty(uid, 'uid'));
  }

  /// Saves the caregiver's profile (`users/{uid}`). Merges, so alerts and
  /// contacts sub-collections and any other fields are untouched.
  Future<void> saveUserProfile(
    String uid, {
    required String displayName,
    String? phone,
  }) async {
    await _profileRef(uid).set({
      'displayName': displayName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'role': 'caregiver',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Live profile fields, or null if no profile document exists.
  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _profileRef(uid).snapshots().map((doc) => doc.data());
  }

  // ---------- ALERTS ----------

  CollectionReference<Map<String, dynamic>> _alertsRef(String uid) {
    return _db
        .collection('users')
        .doc(_requireNonEmpty(uid, 'uid'))
        .collection('alerts');
  }

  /// Live stream of the newest [limit] alerts, newest first.
  ///
  /// Note: Firestore `orderBy` skips documents that lack the field, so the
  /// backend must always write `timestamp` (use a server timestamp).
  Stream<List<AlertModel>> alertsStream(
    String uid, {
    int limit = defaultAlertPageSize,
  }) {
    return _alertsRef(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  /// Older alerts for "load more": pass the timestamp of the last alert
  /// currently shown.
  Future<List<AlertModel>> fetchAlertsBefore(
    String uid,
    DateTime before, {
    int limit = defaultAlertPageSize,
  }) async {
    final snapshot = await _alertsRef(uid)
        .orderBy('timestamp', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AlertModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }

  /// Marks a pending alert as acknowledged. Never deletes anything.
  ///
  /// Returns true if the alert is acknowledged (or already was / is
  /// resolved), false if it doesn't exist. Uses a transaction so it can't
  /// overwrite a newer status, and it needs a connection: offline it fails
  /// instead of pretending to succeed.
  Future<bool> acknowledgeAlert(String uid, String alertId) async {
    final ref = _alertsRef(uid).doc(_requireNonEmpty(alertId, 'alertId'));

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;

      final current = alertStatusFromString(snap.data()?['status']);
      if (current != AlertStatus.pending) return true;

      tx.update(ref, {
        'status': AlertStatus.acknowledged.name,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Generic status change (e.g. to `resolved`). Prefer [acknowledgeAlert]
  /// for the normal acknowledge action.
  Future<void> updateAlertStatus(
    String uid,
    String alertId,
    AlertStatus status,
  ) async {
    await _alertsRef(uid)
        .doc(_requireNonEmpty(alertId, 'alertId'))
        .update({
      'status': status.name,
      if (status == AlertStatus.acknowledged)
        'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }

  /// LEGACY. Alerts should be written by the backend/ESP32, using the unique
  /// event id as the document id so retries can't create duplicates.
  ///
  /// If this is still called from the app:
  /// * with a non-empty `alert.id` it is idempotent (an existing alert is
  ///   never overwritten) and returns false when it already existed;
  /// * with an empty id it creates a new document, which CAN duplicate if the
  ///   same event is reported twice. Give each event a stable id.
  @Deprecated('Alerts should be created by the backend, not the app.')
  Future<bool> addAlert(String uid, AlertModel alert) async {
    final col = _alertsRef(uid);

    if (alert.id.isEmpty) {
      await col.add(alert.toMap());
      return true;
    }

    final ref = col.doc(alert.id);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return false;
      tx.set(ref, alert.toMap());
      return true;
    });
  }

  // (deleteAlert was removed on purpose: acknowledging must never delete the
  // original event.)

  // ---------- EMERGENCY CONTACTS ----------

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return _db
        .collection('users')
        .doc(_requireNonEmpty(uid, 'uid'))
        .collection('contacts');
  }

  /// Contacts sorted by priority, then name. Sorted on the device rather
  /// than with `orderBy`, so older contacts without a `priority`/`createdAt`
  /// field are still returned and no composite index is needed.
  Stream<List<EmergencyContact>> contactsStream(String uid) {
    return _contactsRef(uid).snapshots().map((snapshot) {
      final contacts = snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data(), docId: doc.id))
          .toList();
      contacts.sort(_compareContacts);
      return contacts;
    });
  }

  static int _compareContacts(EmergencyContact a, EmergencyContact b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Creates the contact and returns its new id.
  Future<String> addContact(String uid, EmergencyContact contact) async {
    final ref = await _contactsRef(uid).add({
      ...contact.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateContact(String uid, EmergencyContact contact) async {
    await _contactsRef(uid)
        .doc(_requireNonEmpty(contact.id, 'contact.id'))
        .update(contact.toMap());
  }

  Future<void> deleteContact(String uid, String contactId) async {
    await _contactsRef(uid)
        .doc(_requireNonEmpty(contactId, 'contactId'))
        .delete();
  }
}