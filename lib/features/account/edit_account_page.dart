import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/db/app_data.dart';
import '../community/search_page.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State
  String? _selectedGender;
  DateTime? _selectedDOB;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  String? _selectedBloodGroup;
  bool isDonor = true;

  bool _isLoading = false;
  var uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _mobileNumberController.text = data['mobileNumber'] ?? '';
      _selectedGender = data['gender'];
      if (data['dateOfBirth'] != null) {
        _selectedDOB = DateTime.parse(data['dateOfBirth']);
      }
      _selectedBloodGroup = data['bloodGroup'];
      isDonor = data['isDonor'] ?? true;

      // Address
      if (data['address'] != null && data['address'].isNotEmpty) {
        final addr = data['address'][0];
        _locationController.text = addr['currentAddress'] ?? '';
        _selectedDistrict = addr['district'];
        _selectedSubdistrict = addr['subdistrict'];
      }
    } catch (e) {
      log("Error fetching user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'mobileNumber': _mobileNumberController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'bloodGroup': _selectedBloodGroup,
        'isDonor': isDonor,
        'address': [
          {
            'type': 'current',
            'currentAddress': _locationController.text.trim(),
            'district': _selectedDistrict,
            'subdistrict': _selectedSubdistrict,
          },
        ],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      log("Error updating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDOB = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Gender & DOB
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        hint: const Text('Gender'),
                        items: ['Male', 'Female', 'Other'].map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedGender = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                            ),
                            controller: TextEditingController(
                              text: _selectedDOB == null
                                  ? ''
                                  : '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}',
                            ),
                            validator: (v) =>
                                _selectedDOB == null ? 'Required' : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Mobile
                TextFormField(
                  controller: _mobileNumberController,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Address
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: _selectedDistrict ?? 'Select District',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () async {
                        final selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchPage(
                              title: 'District',
                              items: AppData.districts
                                  .map((d) => d.name)
                                  .toList(),
                            ),
                          ),
                        );
                        if (selected != null) {
                          setState(() => _selectedDistrict = selected);
                        }
                      },
                    ),
                  ),
                  validator: (_) =>
                      _selectedDistrict == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  enabled: _selectedDistrict != null,
                  decoration: InputDecoration(
                    hintText: _selectedSubdistrict ?? 'Select Subdistrict',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () async {
                        if (_selectedDistrict == null) return;
                        final subDistricts = AppData.districts
                            .firstWhere((d) => d.name == _selectedDistrict)
                            .subDistricts;
                        final selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchPage(
                              title: 'Subdistrict',
                              items: subDistricts,
                            ),
                          ),
                        );
                        if (selected != null)
                          setState(() => _selectedSubdistrict = selected);
                      },
                    ),
                  ),
                  validator: (_) =>
                      _selectedSubdistrict == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Blood Group
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  hint: const Text('Blood Group'),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Donor status
                CheckboxListTile(
                  title: const Text('Sign up as Donor'),
                  value: isDonor,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => isDonor = v!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateUser,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
