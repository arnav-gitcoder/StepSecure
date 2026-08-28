import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alert_model.dart';
import '../models/emergency_contact.dart';

/// Handles Firestore reads/writes for alerts + emergency contacts.
/// Scoped per user via uid — pass current user's uid into every call.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- ALERTS ----------

  CollectionReference<Map<String, dynamic>> _alertsRef(String uid) {
    return _db.collection('users').doc(uid).collection('alerts');
  }

  /// Live stream of alerts, newest first.
  Stream<List<AlertModel>> alertsStream(String uid) {
    return _alertsRef(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AlertModel.fromMap(doc.data(), docId: doc.id))
            .toList());
  }

  Future<void> addAlert(String uid, AlertModel alert) async {
    await _alertsRef(uid).add(alert.toMap());
  }

  Future<void> updateAlertStatus(
    String uid,
    String alertId,
    AlertStatus status,
  ) async {
    await _alertsRef(uid).doc(alertId).update({'status': status.name});
  }

  Future<void> deleteAlert(String uid, String alertId) async {
    await _alertsRef(uid).doc(alertId).delete();
  }

  // ---------- EMERGENCY CONTACTS ----------

  CollectionReference<Map<String, dynamic>> _contactsRef(String uid) {
    return _db.collection('users').doc(uid).collection('contacts');
  }

  Stream<List<EmergencyContact>> contactsStream(String uid) {
    return _contactsRef(uid).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.data(), docId: doc.id))
        .toList());
  }

  Future<void> addContact(String uid, EmergencyContact contact) async {
    await _contactsRef(uid).add(contact.toMap());
  }

  Future<void> updateContact(String uid, EmergencyContact contact) async {
    await _contactsRef(uid).doc(contact.id).update(contact.toMap());
  }

  Future<void> deleteContact(String uid, String contactId) async {
    await _contactsRef(uid).doc(contactId).delete();
  }
}