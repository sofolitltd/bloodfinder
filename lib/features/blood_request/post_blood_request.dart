import 'package:bloodfinder/data/db/app_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/blood_request.dart';
import '../community/search_page.dart';

class BloodRequestPage extends StatefulWidget {
  const BloodRequestPage({super.key});

  @override
  State<BloodRequestPage> createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends State<BloodRequestPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBloodGroup;
  String? _selectedBag;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  final List<String> _bagOptions = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
  ];

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _mobileController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a time')));
      return;
    }

    //
    var docRef = FirebaseFirestore.instance.collection('blood_requests').doc();

    var uid = FirebaseAuth.instance.currentUser!.uid;

    //
    final bloodRequest = BloodRequest(
      id: docRef.id,
      uid: uid.toString(),
      name: _nameController.text.trim(),
      bloodGroup: _selectedBloodGroup!,
      bag: _selectedBag!,
      address: _addressController.text.trim(),
      district: _selectedDistrict!,
      subdistrict: _selectedSubdistrict!,
      mobile: _mobileController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      date: DateFormat('d/M/yyy').format(_selectedDate!),
      time: _selectedTime!.format(context),
      createdAt: DateTime.now(),
    );

    try {
      setState(() => _isLoading = true);

      await docRef.set(bloodRequest.toJson());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request posted successfully')),
      );

      Navigator.pop(context); // go back after success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Blood Request'),
        centerTitle: true,
      ),
      body: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      hintText: 'Enter Patient Name',
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      hintText: 'Enter contact number',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only allow digits
                      LengthLimitingTextInputFormatter(11), // Max 11 digits
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length != 11) {
                        return 'Mobile number must be 11 digits';
                      }
                      if (!RegExp(r'^\d{11}$').hasMatch(v)) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Blood Group & Bag
                  Row(
                    children: [
                      Expanded(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Blood Group',
                            ),
                            initialValue: _selectedBloodGroup,
                            items: AppData.bloodGroups
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedBloodGroup = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Bag(s)',
                            ),
                            initialValue: _selectedBag,
                            items: _bagOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedBag = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address / Hospital',
                      hintText: 'Enter address',
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // District & Subdistrict
                  _buildDistrictDropdown(),
                  const SizedBox(height: 16),
                  _buildSubDistrictDropdown(),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat(
                                      'd/M/yyy',
                                    ).format(_selectedDate!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                            ),
                            child: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Note (optional)
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Request'),
                  ),
                ],
              ),
            ),
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
      validator: (_) =>
          _selectedDistrict == null ? 'Please select a district' : null,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubdistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedSubdistrict = null),
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
          setState(() => _selectedSubdistrict = selectedValue);
        }
      },
      validator: (_) =>
          _selectedSubdistrict == null ? 'Please select a subdistrict' : null,
    );
  }
}
