import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/phone_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'blood_bank_seed_data.dart';

class BloodBankForm extends StatefulWidget {
  const BloodBankForm({super.key});

  @override
  State<BloodBankForm> createState() => _BloodBankFormState();
}

class _BloodBankFormState extends State<BloodBankForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobile1Controller = TextEditingController();
  final TextEditingController _mobile2Controller = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  Timer? _debounce;

  bool? _slugIsUnique;
  bool _checkingSlug = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _addressController.dispose();
    _mobile1Controller.dispose();
    _websiteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _slugController.text = '';
        _slugIsUnique = null;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final slug = _generateSlug(name);
      _slugController.text = slug;
      await _checkSlugUnique(slug);
    });
  }

  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _checkSlugUnique(String slug) async {
    setState(() {
      _checkingSlug = true;
      _slugIsUnique = null;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('blood_bank')
        .where('slug', isEqualTo: slug)
        .get();

    setState(() {
      _checkingSlug = false;
      _slugIsUnique = querySnapshot.docs.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Name'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter blood bank name',
              border: OutlineInputBorder(),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Enter name' : null,
          ),
          SizedBox(height: 1.h),

          _buildLabel('Slug (auto-generated)'),
          TextFormField(
            controller: _slugController,
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: const OutlineInputBorder(),
              suffixIcon: _checkingSlug
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _slugIsUnique == null
                  ? null
                  : _slugIsUnique == true
                  ? Icon(
                      PhosphorIcons.checkCircle,
                      color: Colors.green,
                    )
                  : Icon(PhosphorIcons.xCircle, color: Colors.red),
            ),
          ),
          SizedBox(height: 1.h),

          _buildLabel('Address'),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Enter address',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Enter address'
                : null,
          ),
          SizedBox(height: 1.h),

          _buildLabel('Mobile'),
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mobile1Controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter mobile1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter mobile No';
                    }
                    return null;
                  },
                ),
              ),

              Expanded(
                child: TextFormField(
                  controller: _mobile2Controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter mobile2',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          _buildLabel('Website (optional)'),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              hintText: 'Enter website URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            validator: (val) {
              if (val != null && val.isNotEmpty) {
                final urlPattern =
                    r'^(https?:\/\/)?([\w\-]+)+([\w\-\.]+)+[\w\-\/]*$';
                final regex = RegExp(urlPattern);
                if (!regex.hasMatch(val)) return 'Invalid URL';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final firestore = FirebaseFirestore.instance;

                for (final bloodBank in bloodBanks) {
                  final slug = bloodBank['slug'];

                  final query = await firestore
                      .collection('blood_bank')
                      .where('slug', isEqualTo: slug)
                      .limit(1)
                      .get();

                  if (query.docs.isEmpty) {
                    // Normalize phone numbers to canonical format
                    final normalized = Map<String, dynamic>.from(bloodBank);
                    if (normalized['mobile1'] != null) {
                      normalized['mobile1'] =
                          PhoneUtils.toCanonical(normalized['mobile1']);
                    }
                    if (normalized['mobile2'] != null) {
                      normalized['mobile2'] =
                          PhoneUtils.toCanonical(normalized['mobile2']);
                    }
                    await firestore
                        .collection('blood_bank')
                        .add(normalized);
                    log('Added: ${bloodBank['name']}');
                  } else {
                    log(
                      'Skipped (already exists): ${bloodBank['name']}',
                    );
                  }
                }

                log('Upload completed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: Text(
                'Add Blood Bank',
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 6.h),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}
