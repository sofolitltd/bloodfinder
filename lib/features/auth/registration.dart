import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart'; // For saving user data
import 'package:firebase_auth/firebase_auth.dart'; // For authentication
import 'package:flutter/material.dart';

import '../../data/db/app_data.dart';
import '../community/search_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // GlobalKey for form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text Editing Controllers for various input fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(); // Current Address

  // Focus Nodes for field navigation
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _mobileNumberFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _districtFocus = FocusNode();
  final FocusNode _thanaFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // State variables for dropdowns and selections
  String? _selectedGender; // Made nullable for initial state
  DateTime? selectedDateOfBirth;
  String? _selectedBloodGroup; // Made nullable for initial state
  bool isDonor = true;

  // State variables for Autocomplete (District and Thana)
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileNumberController.dispose();
    _locationController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _mobileNumberFocus.dispose();
    _locationFocus.dispose();
    _districtFocus.dispose();
    _thanaFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Helper to show SnackBar messages
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDateOfBirth) {
      setState(() {
        selectedDateOfBirth = picked;
      });
    }
  }

  // Handle User Registration
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please fix the errors in the form.', isError: true);

      return;
    }

    // Basic validation for dropdowns and date picker
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _showMessage('Please select your Gender.', isError: true);
      return;
    }
    if (selectedDateOfBirth == null) {
      _showMessage('Please select your Date of Birth.', isError: true);
      return;
    }
    if (_selectedDistrict == null) {
      _showMessage('Please select your District.', isError: true);
      return;
    }
    if (_selectedSubdistrict == null) {
      _showMessage('Please select your Thana.', isError: true);
      return;
    }
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      _showMessage('Please select your Blood Group.', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // 1. Create User with Email and Password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Save Additional User Data to Firestore
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobileNumber': _mobileNumberController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': selectedDateOfBirth!.toIso8601String(),
        // Store as ISO String
        //address as {}
        'address': [
          {
            'type': 'current',
            'currentAddress': _locationController.text.trim(),
            'district': _selectedDistrict,
            'subdistrict': _selectedSubdistrict,
          },
        ],
        'communities': [],
        'bloodGroup': _selectedBloodGroup,
        'isDonor': isDonor,
        'isEmergencyDonor': false,
        'token': '',
        'createdAt': FieldValue.serverTimestamp(), // Timestamp of creation
      });

      // _showMessage('Registration Successful! Please log in.', isError: false);
      setState(() => _isLoading = false);
      // Navigate back to the login screen after successful registration
      Navigator.pushReplacementNamed(
        context,
        '/',
      ); // Use pushReplacementNamed to prevent back navigation
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Firebase Auth Error: ${e.message}';
      }
      _showMessage(errorMessage, isError: true);
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      _showMessage(
        'An unexpected error occurred: ${e.toString()}',
        isError: true,
      );
      log('General Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey, // Assign the form key
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // First Name & Last Name
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        // Changed to TextFormField
                        controller: _firstNameController,
                        focusNode: _firstNameFocus,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_lastNameFocus),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'First Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        // Changed to TextFormField
                        controller: _lastNameController,
                        focusNode: _lastNameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(
                              _mobileNumberFocus,
                            ), // Next to mobile if gender/dob aren't TextFormFields
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gender & Date of Birth
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _selectedGender, // Use nullable value directly
                          hint: const Text('Gender'),
                          decoration: const InputDecoration(
                            // Removed fill and borderSide.none for Dropdown to match TextField
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          items: <String>['Male', 'Female', 'Other'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Gender is required';
                            }
                            return null;
                          },
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
                            // Changed to TextFormField for consistent styling
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              // suffixIcon: const Icon(Icons.calendar_today), // Consider adding back if you want a visual cue
                            ),
                            controller: TextEditingController(
                              text: selectedDateOfBirth == null
                                  ? ''
                                  : '${selectedDateOfBirth!.day}/${selectedDateOfBirth!.month}/${selectedDateOfBirth!.year}',
                            ),
                            validator: (value) {
                              if (selectedDateOfBirth == null) {
                                return 'DOB is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  // Changed to TextFormField
                  controller: _mobileNumberController,
                  focusNode: _mobileNumberFocus,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_locationFocus),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mobile Number is required';
                    }
                    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                      // Basic 11-digit check for BD numbers
                      return 'Enter a valid 11-digit mobile number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // address
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Current Address
                TextFormField(
                  // Changed to TextFormField
                  controller: _locationController,
                  focusNode: _locationFocus,
                  decoration: const InputDecoration(
                    labelText: 'Current Address',
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_districtFocus),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Current Address is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                //
                // District Dropdown
                _buildDistrictDropdown(),

                const SizedBox(height: 16),

                // Sub-District Dropdown
                _buildSubDistrictDropdown(),

                const SizedBox(height: 24),

                //
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Blood',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Blood Group & Sign up as donor
                //
                ButtonTheme(
                  alignedDropdown: true,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBloodGroup,
                    hint: const Text('Select Blood Group'),
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    items:
                        <String>[
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'AB+',
                          'AB-',
                          'O+',
                          'O-',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBloodGroup = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Blood Group is required';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 8),

                //
                CheckboxListTile(
                  visualDensity: VisualDensity.compact,
                  title: const Text('Sign up as Donor'),
                  value: isDonor,
                  onChanged: (bool? newValue) {
                    setState(() {
                      isDonor = newValue!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Email
                TextFormField(
                  // Changed to TextFormField
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegistration(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _handleRegistration, // Call the registration handler

                  child: _isLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Create Account'),
                ),

                const SizedBox(height: 20),

                // Already have an account? Sign In
                TextButton(
                  onPressed: () {
                    // Navigate to sign in screen
                    Navigator.pop(
                      context,
                    ); // Pop the current registration screen
                    // Or, if you want to ensure it's the root login page:
                    // Navigator.pushReplacementNamed(context, '/');
                  },
                  child: Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //
  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        // labelText: 'District',
        hintText: _selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedDistrict = null;
                    _selectedSubdistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPage(
              title: 'District',
              items: (AppData.districts.map((d) => d.name).toList()..sort()),
            ),
          ),
        );
        if (selectedValue != null) {
          setState(() {
            _selectedDistrict = selectedValue;
            _selectedSubdistrict = null;
          });
        }
      },
      validator: (value) {
        if (_selectedDistrict == null) {
          return 'Please select a district';
        }
        return null;
      },
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
