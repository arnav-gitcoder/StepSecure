import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';
import 'package:stepsecure_app/services/auth_service.dart';

class _Contact {
  String name;
  String relation;
  String phone;
  Color color;
  bool isPrimary;
  final bool isLocked; // true for the account holder's own contact

  _Contact({
    required this.name,
    required this.relation,
    required this.phone,
    required this.color,
    this.isPrimary = false,
    this.isLocked = false,
  });
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late final List<_Contact> contacts;

  @override
  void initState() {
    super.initState();

    // Placeholder until _loadSelfContact() fills in the real saved
    // name/phone below — avoids a null-check window before first frame.
    contacts = [
      _Contact(
        name: "Me",
        relation: "Account Holder",
        phone: "Loading...",
        color: AppColors.primary,
        isPrimary: true,
        isLocked: true,
      ),
      _Contact(
        name: "John Doe",
        relation: "Secondary Contact",
        phone: "+91 98765 12345",
        color: AppColors.success,
      ),
      _Contact(
        name: "Family Member",
        relation: "Emergency Backup",
        phone: "+91 99999 99999",
        color: AppColors.warning,
      ),
    ];

    _loadSelfContact();
  }

  Future<void> _loadSelfContact() async {
    // TODO: once a Firestore user-profile layer exists, read from
    // there instead — SharedPreferences is local-only, so this won't
    // follow the account to a different device.
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('registered_name_${user.uid}');
    final savedPhone = prefs.getString('registered_phone_${user.uid}');

    if (!mounted) return;
    setState(() {
      contacts[0].name = (savedName?.isNotEmpty ?? false)
          ? savedName!
          : (user.displayName?.isNotEmpty == true
              ? user.displayName!
              : "Me");
      contacts[0].phone = (savedPhone?.isNotEmpty ?? false)
          ? savedPhone!
          : (user.phoneNumber ?? "Not set — edit to add");
    });
  }

  Future<void> _callContact(_Contact contact) async {
    // Strip anything that isn't a digit or a leading +, since tel: URIs
    // don't tolerate spaces/formatting the way display text does.
    final cleaned = contact.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);

    final launched = await launchUrl(uri);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't open a dialer for ${contact.name}. "
            "This works best on a phone — desktop browsers need a "
            "calling app (like Skype) registered for tel: links.",
          ),
        ),
      );
    }
  }

  void _setPrimary(int index) {
    setState(() {
      for (var i = 0; i < contacts.length; i++) {
        contacts[i].isPrimary = (i == index);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${contacts[index].name} is now the SOS contact"),
      ),
    );
  }

  void _deleteContact(int index) {
    if (contacts[index].isLocked) return; // safety net; UI already hides this

    final wasPrimary = contacts[index].isPrimary;
    setState(() {
      contacts.removeAt(index);
      // If the primary contact was removed, fall back to the account
      // holder rather than leaving no primary at all.
      if (wasPrimary && contacts.isNotEmpty) {
        contacts[0].isPrimary = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contact removed")),
    );
  }

  void _showContactDialog({_Contact? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final relationController =
        TextEditingController(text: existing?.relation ?? '');
    String? fullPhone = existing?.phone;
    bool phoneValid = isEditing; // existing numbers assumed valid already
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text(
            isEditing ? "Edit Contact" : "Add Contact",
            style: AppStyles.cardTitle.copyWith(color: cs.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: "Relation"),
                ),
                const SizedBox(height: 12),
                IntlPhoneField(
                  initialCountryCode: 'IN',
                  initialValue: isEditing ? existing.phone : null,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    counterText: '',
                  ),
                  onChanged: (phone) {
                    // Space between country code and number —
                    // phone.completeNumber concatenates them with none
                    // (e.g. "+9198765..."), which is what caused the
                    // missing gap after editing.
                    fullPhone = '${phone.countryCode} ${phone.number}';
                    try {
                      phoneValid = phone.isValidNumber();
                    } catch (_) {
                      phoneValid = false;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    relationController.text.isEmpty ||
                    fullPhone == null ||
                    fullPhone!.isEmpty ||
                    !phoneValid) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text("Fill all fields with a valid number"),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (isEditing) {
                    existing.name = nameController.text;
                    existing.relation = relationController.text;
                    existing.phone = fullPhone!;
                  } else {
                    contacts.add(
                      _Contact(
                        name: nameController.text,
                        relation: relationController.text,
                        phone: fullPhone!,
                        color: AppColors.primary,
                      ),
                    );
                  }
                });

                // The locked "Me" contact is the account holder's own
                // info — persist edits to it so they survive a
                // restart, same as what registration saves.
                // TODO: move to Firestore alongside the same TODO in
                // register_screen.dart once that layer exists.
                if (isEditing && existing.isLocked) {
                  final user = AuthService.instance.currentUser;
                  if (user != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'registered_name_${user.uid}',
                      nameController.text,
                    );
                    await prefs.setString(
                      'registered_phone_${user.uid}',
                      fullPhone!,
                    );
                  }
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(isEditing ? "Save" : "Add"),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      relationController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Emergency Contacts",
          style: AppStyles.headingSmall.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildContactCard(
                    index: index,
                    contact: contacts[index],
                    cardColor: cs.surface,
                    textColor: cs.onSurface,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _showContactDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text("Add Contact", style: AppStyles.buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required int index,
    required _Contact contact,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: contact.isPrimary
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: contact.color.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: contact.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: AppStyles.cardTitle.copyWith(
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact.isLocked) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ],
                      ],
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
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _callContact(contact),
                icon: const Icon(Icons.call, color: AppColors.success),
              ),
              IconButton(
                onPressed: () => _showContactDialog(existing: contact),
                icon: Icon(
                  Icons.edit_outlined,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              IconButton(
                // Locked contact can't be deleted — disabled rather than
                // hidden, so it's clear this is intentional, not a bug.
                onPressed:
                    contact.isLocked ? null : () => _deleteContact(index),
                icon: Icon(
                  Icons.delete_outline,
                  color: contact.isLocked
                      ? textColor.withValues(alpha: 0.2)
                      : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (contact.isPrimary)
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
                        "SOS PRIMARY",
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
                  onPressed: () => _setPrimary(index),
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text("Make SOS primary"),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}