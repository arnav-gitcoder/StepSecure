// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, dynamic>> contacts = [
    {
      "name": "Arnav Srivastava",
      "relation": "Primary Contact",
      "phone": "+91 98765 43210",
      "color": AppColors.primary,
    },
    {
      "name": "John Doe",
      "relation": "Secondary Contact",
      "phone": "+91 98765 12345",
      "color": AppColors.success,
    },
    {
      "name": "Family Member",
      "relation": "Emergency Backup",
      "phone": "+91 99999 99999",
      "color": AppColors.warning,
    },
  ];

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          "Add Contact",
          style: AppStyles.cardTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: "Relation",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  relationController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                return;
              }

              setState(() {
                contacts.add({
                  "name": nameController.text,
                  "relation": relationController.text,
                  "phone": phoneController.text,
                  "color": AppColors.primary,
                });
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Contact removed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Emergency Contacts",
          style: AppStyles.headingSmall,
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: contacts.isEmpty
                  ? const Center(
                      child: Text(
                        "No contacts added yet",
                        style: AppStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];

                        return _buildContactCard(
                          name: contact["name"],
                          relation: contact["relation"],
                          phone: contact["phone"],
                          color: contact["color"],
                          onDelete: () => _deleteContact(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  "Add Contact",
                  style: AppStyles.buttonText,
                ),
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
    required String name,
    required String relation,
    required String phone,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withAlpha(40),
            child: Icon(
              Icons.person,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  relation,
                  style: AppStyles.cardSubtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: AppStyles.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Calling $name"),
                ),
              );
            },
            icon: const Icon(
              Icons.call,
              color: AppColors.success,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}