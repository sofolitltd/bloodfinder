import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/db/app_data.dart';
import '../../data/models/user_model.dart';
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
  String? _profileImageUrl;
  File? _selectedImage;

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
      UserModel user = UserModel.fromJson(data);

      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _mobileNumberController.text = user.mobileNumber;
      _selectedGender = user.gender;
      _selectedDOB = DateTime.tryParse(data['dateOfBirth']);
      _selectedBloodGroup = user.bloodGroup;
      isDonor = user.isDonor;
      _profileImageUrl = user.image;
      // Address
      _locationController.text = user.currentAddress;
      _selectedDistrict = user.district;
      _selectedSubdistrict = user.subdistrict;
    } catch (e) {
      log("Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile data'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'mobileNumber': _mobileNumberController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'bloodGroup': _selectedBloodGroup,
        'isDonor': isDonor,
        'image': imageUrl,
        'currentAddress': _locationController.text.trim(), // Flat structure
        'district': _selectedDistrict, // Flat structure
        'subdistrict': _selectedSubdistrict, // Flat structure
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

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users/$uid.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      log("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload image'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: _selectedDistrict ?? 'Select District',
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              title: 'District',
              items: AppData.districts.map((d) => d.name).toList(),
            ),
          ),
        );
        if (selected != null) {
          setState(() {
            _selectedDistrict = selected;
            _selectedSubdistrict =
                null; // Reset subdistrict when district changes
          });
        }
      },
      validator: (_) => _selectedDistrict == null ? 'Required' : null,
    );
  }

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
        hintText: _selectedSubdistrict ?? 'Select Subdistrict',
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selected != null) {
          setState(() => _selectedSubdistrict = selected);
        }
      },
      validator: (_) => _selectedSubdistrict == null ? 'Required' : null,
    );
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
                // Avatar with edit button
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            _selectedImage == null && _profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Gender & DOB
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          hint: const Text('Gender'),
                          items: ['Male', 'Female'].map((g) {
                            return DropdownMenuItem(value: g, child: Text(g));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Only allow digits
                    LengthLimitingTextInputFormatter(11), // Max 11 digits
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 11)
                      return 'Mobile number must be 11 digits';
                    if (!RegExp(r'^\d{11}$').hasMatch(v))
                      return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Address
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Current Address',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildDistrictDropdown(),
                const SizedBox(height: 12),
                _buildSubDistrictDropdown(),
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
