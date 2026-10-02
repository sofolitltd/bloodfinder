import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/phone_utils.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/my_circle_contact.dart';
import '../../providers/my_circle_provider.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  const AddContactSheet({super.key});

  @override
  ConsumerState<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedBloodGroup = 'A+';
  String _selectedRelation = 'Friend';
  bool _isLoading = false;

  /// Set when the entered phone matches an existing circle contact.
  MyCircleContact? _duplicateContact;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _relationOptions = [
    'Friend',
    'Family',
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Spouse',
    'Relative',
    'Colleague',
    'Neighbour',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkDuplicate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Look up the current phone against existing circle contacts.
  void _checkDuplicate() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (_duplicateContact != null) {
        setState(() => _duplicateContact = null);
      }
      return;
    }

    final existing =
        ref.read(myCircleProvider).asData?.value ?? <MyCircleContact>[];
    final match = existing.cast<MyCircleContact?>().firstWhere(
      (c) => PhoneUtils.match(c!.phone, phone),
      orElse: () => null,
    );

    if (match != _duplicateContact) {
      setState(() => _duplicateContact = match);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        PhosphorIcons.userPlus,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Add Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person, size: 20),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(PhosphorIcons.addressBookTabs, size: 20),
                      tooltip: 'Pick from contacts',
                      onPressed: _pickFromContacts,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),

                // Duplicate warning
                if (_duplicateContact != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Already in your circle as '
                            '"${_duplicateContact!.name}" '
                            '(${_duplicateContact!.relation})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype, size: 20),
                  ),
                  items: _bloodGroups
                      .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBloodGroup = v);
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRelation,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: Icon(PhosphorIcons.usersThree, size: 20),
                  ),
                  items: _relationOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedRelation = v);
                  },
                ),
                SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_duplicateContact != null
                              ? _confirmAddDuplicate
                              : _addContact),
                    style: ElevatedButton.styleFrom(elevation: 0),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _duplicateContact != null
                                ? 'Add Anyway'
                                : 'Save Contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromContacts() async {
    try {
      final permissionStatus = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (permissionStatus != PermissionStatus.granted &&
          permissionStatus != PermissionStatus.limited) {
        return;
      }

      final picked = await FlutterContacts.native.showPicker(
        properties: ContactProperties.all,
      );
      if (picked == null) return;

      final displayName = picked.displayName;
      final nameObj = picked.name;
      final name = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : '${nameObj?.first ?? ''} ${nameObj?.last ?? ''}'.trim();
      if (name.isNotEmpty) {
        _nameController.text = name;
      }

      if (picked.phones.isNotEmpty) {
        final phone = picked.phones.first;
        final normalized = phone.normalizedNumber;
        _phoneController.text = (normalized != null && normalized.isNotEmpty)
            ? normalized
            : phone.number;
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
  }

  Future<void> _confirmAddDuplicate() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Already in Circle'),
        content: Text(
          '"${_duplicateContact!.name}" is already in your circle '
          'as ${_duplicateContact!.relation} (${_duplicateContact!.bloodGroup}).\n\n'
          'Add them again anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Add Anyway',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
    if (proceed == true) {
      _addContact();
    }
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ownerId = ref.read(authRepositoryProvider).currentUser!.uid;
      final repo = ref.read(myCircleRepositoryProvider);
      final phone = PhoneUtils.toCanonical(_phoneController.text.trim());

      final contactId = await repo.addContact(ownerId, {
        'ownerId': ownerId,
        'name': _nameController.text.trim(),
        'phone': phone,
        'bloodGroup': _selectedBloodGroup,
        'relation': _selectedRelation,
        'isAppUser': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Check if this phone belongs to a registered app user and link immediately
      await repo.checkAndLinkAppUser(ownerId, contactId, phone);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contact added')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
