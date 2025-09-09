import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '/data/db/app_data.dart';
import '/data/models/user_model.dart';
import '../community/search_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dob;
  String? _gender;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  String? _bloodGroup;
  bool isDonor = true;
  XFile? _pickedImage;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Pick image and compress
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressed = await _compressImage(File(pickedFile.path));
      setState(() {
        _pickedImage = compressed; // File? type, works perfectly
      });
    }
  }

  Future<XFile?> _compressImage(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/compressed_${file.path.split('/').last}',
      quality: 70, // adjust for smaller size
      minWidth: 500,
      minHeight: 500,
    );

    return compressedFile; // already File? type
  }

  Future<String> _uploadImage(File file, String uid) async {
    final ref = FirebaseStorage.instance.ref().child('users/$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Create Firebase Auth User
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;
      String imageUrl = '';

      if (_pickedImage != null) {
        imageUrl = await _uploadImage(File(_pickedImage!.path), uid);
      }

      //
      final createdAt = DateTime.now().toIso8601String();

      //
      var token = await FirebaseMessaging.instance.getToken();

      // Create UserModel
      final user = UserModel(
        uid: uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        gender: _gender!,
        dateOfBirth: _dob!,
        currentAddress: _addressController.text.trim(),
        district: _selectedDistrict!,
        subdistrict: _selectedSubdistrict!,
        communities: [],
        bloodGroup: _bloodGroup!,
        isDonor: isDonor,
        isEmergencyDonor: false,
        token: token ?? '',
        createdAt: createdAt,
        isOnline: false,
        image: imageUrl,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(user.toJson());

      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(context, '/'); // Go to login/home
    } on FirebaseAuthException catch (e) {
      log('FirebaseAuth Error: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      log('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : null,
                  child: _pickedImage == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // First & Last Name
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender & DOB
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        hint: const Text('Select Gender'),
                        items: ['Male', 'Female']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            text: _dob == null
                                ? ''
                                : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                          ),
                          validator: (_) => _dob == null ? 'Required' : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mobile
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Only allow digits
                  LengthLimitingTextInputFormatter(11), // Max 11 digits
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 11) return 'Mobile number must be 11 digits';
                  if (!RegExp(r'^\d{11}$').hasMatch(v)) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Current Address'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // District & Subdistrict
              _buildDistrictDropdown(),
              const SizedBox(height: 16),
              _buildSubDistrictDropdown(),
              const SizedBox(height: 16),

              // Blood Group
              ButtonTheme(
                alignedDropdown: true,
                child: DropdownButtonFormField<String>(
                  initialValue: _bloodGroup,
                  hint: const Text('Blood Group'),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodGroup = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              CheckboxListTile(
                title: const Text('Sign up as Donor'),
                value: isDonor,
                onChanged: (v) => setState(() => isDonor = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),

              // Email & Password
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                child: _isLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: _selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              title: 'District',
              items: (AppData.districts.map((d) => d.name).toList()..sort()),
            ),
          ),
        );
        if (selected != null) {
          setState(() {
            _selectedDistrict = selected;
            _selectedSubdistrict = null;
          });
        }
      },
      validator: (_) => _selectedDistrict == null ? 'Required' : null,
    );
  }

  //
  Widget _buildSubDistrictDropdown() {
    final subDistricts = _selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == _selectedDistrict)
              .subDistricts
        : <String>[];
    return TextFormField(
      readOnly: true,
      enabled: _selectedDistrict != null,
      decoration: InputDecoration(
        // labelText: 'Subdistrict',
        hintText: _selectedSubdistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubdistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedSubdistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selectedValue != null) {
          setState(() {
            _selectedSubdistrict = selectedValue;
          });
        }
      },
      validator: (value) {
        if (_selectedSubdistrict == null) {
          return 'Please select a subdistrict';
        }
        return null;
      },
    );
  }
}
