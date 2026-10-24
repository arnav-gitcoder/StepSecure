import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/models/emergency_contact.dart';
import 'package:stepsecure_app/services/auth_service.dart';
import 'package:stepsecure_app/services/firestore_service.dart';
import 'package:stepsecure_app/utils/data_error_helper.dart';
import 'package:stepsecure_app/utils/validators.dart';

/// Numbers typed without a "+" are assumed to belong to this country.
/// Change it if the app is used outside India. Numbers that start with "+"
/// are always accepted as typed.
const String _defaultCountryCode = '+91';

/// People to alert when the wearer falls, saved to the caregiver's account in
/// Firestore. The first contact in the list is the one to reach first.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirestoreService _firestore = FirestoreService();
  late Stream<List<EmergencyContact>> _stream;

  String? get _uid => AuthService.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _stream = _open();
  }

  Stream<List<EmergencyContact>> _open() {
    try {
      final uid = _uid;
      if (uid == null) return const Stream<List<EmergencyContact>>.empty();
      return _firestore.contactsStream(uid);
    } catch (e) {
      return Stream<List<EmergencyContact>>.error(e);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a write. Firestore queues writes while offline, so a timeout means
  /// "will be saved when you reconnect", not "failed".
  Future<void> _run(
    Future<void> Function() operation, {
    required String success,
  }) async {
    try {
      await operation().timeout(const Duration(seconds: 10));
      if (mounted) _snack(success);
    } on TimeoutException {
      if (mounted) {
        _snack(
          'You appear to be offline. The change will be saved when you '
          'reconnect.',
        );
      }
    } catch (e) {
      if (mounted) _snack(DataErrorHelper.friendlyMessage(e));
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    final number = contact.phoneE164 ?? contact.phone;
    try {
      final launched = await launchUrl(Uri(scheme: 'tel', path: number));
      if (!launched && mounted) {
        _snack("Couldn't open a dialer for ${contact.name} on this device.");
      }
    } catch (_) {
      if (mounted) {
        _snack("Couldn't open a dialer for ${contact.name} on this device.");
      }
    }
  }

  Future<void> _makeFirst(
    EmergencyContact contact,
    List<EmergencyContact> all,
  ) async {
    final uid = _uid;
    if (uid == null || all.isEmpty) return;
    final lowest = all.map((c) => c.priority).reduce((a, b) => a < b ? a : b);

    await _run(
      () => _firestore.updateContact(
        uid,
        contact.copyWith(priority: lowest - 1),
      ),
      success: '${contact.name} will be contacted first.',
    );
  }

  Future<void> _confirmDelete(EmergencyContact contact) async {
    final uid = _uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          '${contact.name} will no longer be on your emergency contact list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _run(
      () => _firestore.deleteContact(uid, contact.id),
      success: 'Contact removed.',
    );
  }

  Future<void> _openContactDialog({
    EmergencyContact? existing,
    required List<EmergencyContact> all,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    // New contacts go to the end of the list.
    final nextPriority = all.isEmpty
        ? 0
        : all.map((c) => c.priority).reduce((a, b) => a > b ? a : b) + 1;

    // Numbers already saved for other contacts, to catch duplicates.
    final takenNumbers = all
        .where((c) => c.id != existing?.id)
        .map((c) => c.phoneE164 ?? c.phone)
        .toSet();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContactDialog(
        existing: existing,
        newPriority: nextPriority,
        takenNumbers: takenNumbers,
        onSave: (contact) => contact.id.isEmpty
            ? _firestore.addContact(uid, contact)
            : _firestore.updateContact(uid, contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _stream,
        builder: (context, snap) {
          final contacts = snap.data;

          Widget content;
          if (snap.hasError) {
            content = _message(
              context,
              icon: Icons.error_outline,
              text: DataErrorHelper.friendlyMessage(snap.error!),
              action: TextButton.icon(
                onPressed: () => setState(() => _stream = _open()),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            );
          } else if (contacts == null) {
            content = const Center(child: CircularProgressIndicator());
          } else if (contacts.isEmpty) {
            content = _message(
              context,
              icon: Icons.people_outline,
              text: 'No emergency contacts yet. Add the people who should '
                  'be alerted if the wearer falls.',
            );
          } else {
            content = ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildContactCard(
                context,
                contact: contacts[index],
                isFirst: index == 0,
                all: contacts,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _deliveryNote(context),
                const SizedBox(height: 12),
                Expanded(child: content),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: contacts == null
                        ? null
                        : () => _openContactDialog(all: contacts),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Contact',
                        style: AppStyles.buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          cs.onSurface.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Saving a number does not message anyone. Say so, until a real
  /// notification service exists.
  Widget _deliveryNote(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Contacts are saved to your account. Automatic alerts to '
              'these contacts are not active yet, so call them yourself if '
              'a fall alert arrives.',
              style: AppStyles.bodySmall.copyWith(color: cs.onSurface),
            ),
          ),
        ],
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
      child: SingleChildScrollView(
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

  Widget _buildContactCard(
    BuildContext context, {
    required EmergencyContact contact,
    required bool isFirst,
    required List<EmergencyContact> all,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst ? AppColors.primary : cs.outlineVariant,
          width: isFirst ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppStyles.cardTitle.copyWith(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relation,
                      style: AppStyles.cardSubtitle.copyWith(
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phone,
                      style: AppStyles.bodyMedium.copyWith(color: textColor),
                    ),
                    if (contact.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.email!,
                        style: AppStyles.bodySmall.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isFirst)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'CONTACT FIRST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => _makeFirst(contact, all),
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text('Contact first'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Call ${contact.name}',
                onPressed: () => _callContact(contact),
                icon: const Icon(Icons.call, color: AppColors.success),
              ),
              IconButton(
                tooltip: 'Edit ${contact.name}',
                onPressed: () =>
                    _openContactDialog(existing: contact, all: all),
                icon: Icon(
                  Icons.edit_outlined,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              IconButton(
                tooltip: 'Delete ${contact.name}',
                onPressed: () => _confirmDelete(contact),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Add / edit form. Owns its controllers so they are always disposed.
class _ContactDialog extends StatefulWidget {
  final EmergencyContact? existing;
  final int newPriority;
  final Set<String> takenNumbers;
  final Future<void> Function(EmergencyContact contact) onSave;

  const _ContactDialog({
    required this.existing,
    required this.newPriority,
    required this.takenNumbers,
    required this.onSave,
  });

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relation;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _relation = TextEditingController(text: e?.relation ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateRelation(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Relation is required';
    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = EmergencyContact.normalizePhone(
      value ?? '',
      defaultCountryCode: _defaultCountryCode,
    );
    if (normalized == null) {
      return 'Enter a valid number, e.g. +91 98765 43210';
    }
    if (widget.takenNumbers.contains(normalized)) {
      return 'This number is already saved';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if ((value ?? '').trim().isEmpty) return null; // optional
    return Validators.email(value);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final normalized = EmergencyContact.normalizePhone(
      _phone.text,
      defaultCountryCode: _defaultCountryCode,
    );
    if (normalized == null) return;

    final email = _email.text.trim();
    final contact = EmergencyContact(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      phone: normalized,
      relation: _relation.text.trim(),
      email: email.isEmpty ? null : email,
      priority: widget.existing?.priority ?? widget.newPriority,
    );

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(contact).timeout(const Duration(seconds: 10));
      if (mounted) Navigator.pop(context);
    } on TimeoutException {
      // Firestore keeps the write and sends it once back online.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You appear to be offline. The contact will be saved when you '
            'reconnect.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = DataErrorHelper.friendlyMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text(
        _isEditing ? 'Edit Contact' : 'Add Contact',
        style: AppStyles.cardTitle.copyWith(color: cs.onSurface),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _relation,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  validator: _validateRelation,
                  decoration: const InputDecoration(
                    labelText: 'Relation',
                    hintText: 'e.g. Daughter, Neighbour, Doctor',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _validatePhone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+91 98765 43210',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}