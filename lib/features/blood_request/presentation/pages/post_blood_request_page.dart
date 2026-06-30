import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../models/blood_request.dart';
import '../widgets/request_form.dart';

class BloodRequestPage extends ConsumerStatefulWidget {
  final BloodRequest? existingRequest;

  const BloodRequestPage({super.key, this.existingRequest});

  @override
  ConsumerState<BloodRequestPage> createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends ConsumerState<BloodRequestPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBloodGroup;
  String? _selectedBag;
  String _status = 'active';

  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _mobileController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  bool get _isEditing => widget.existingRequest != null;

  // Original values for edit-mode change detection
  String? _origBloodGroup;
  String? _origBag;
  String _origStatus = 'active';
  double? _origLatitude;
  double? _origLongitude;
  String? _origLocationAddress;
  DateTime? _origDate;
  TimeOfDay? _origTime;
  String _origName = '';
  String _origAddress = '';
  String _origNote = '';
  String _origMobile = '';

  bool get _hasChanges {
    if (!_isEditing) return true;
    return _nameController.text != _origName ||
        _addressController.text != _origAddress ||
        _noteController.text != _origNote ||
        _mobileController.text != _origMobile ||
        _selectedBloodGroup != _origBloodGroup ||
        _selectedBag != _origBag ||
        _selectedDate != _origDate ||
        _selectedTime != _origTime ||
        _latitude != _origLatitude ||
        _longitude != _origLongitude ||
        _locationAddress != _origLocationAddress ||
        _status != _origStatus;
  }

  final List<String> _bagOptions = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existingRequest;
    if (e != null) {
      _nameController.text = e.name;
      _addressController.text = e.address;
      _noteController.text = e.note ?? '';
      _mobileController.text = e.mobile;
      _selectedBloodGroup = e.bloodGroup;
      _selectedBag = e.bag;
      _latitude = e.latitude;
      _longitude = e.longitude;
      _locationAddress = e.locationAddress;
      _status = e.status;
      try {
        _selectedDate = DateFormat('d/M/yyy').parse(e.date);
      } catch (_) {
        _selectedDate = null;
      }
      try {
        final parts = e.time.split(':');
        if (parts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      } catch (_) {
        _selectedTime = null;
      }
      // Store originals
      _origBloodGroup = e.bloodGroup;
      _origBag = e.bag;
      _origStatus = e.status;
      _origLatitude = e.latitude;
      _origLongitude = e.longitude;
      _origLocationAddress = e.locationAddress;
      _origDate = _selectedDate;
      _origTime = _selectedTime;
      _origName = e.name;
      _origAddress = e.address;
      _origNote = e.note ?? '';
      _origMobile = e.mobile;
    }
    // Listen for text changes to recompute _hasChanges
    _nameController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _noteController.addListener(_onFieldChanged);
    _mobileController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _noteController.removeListener(_onFieldChanged);
    _mobileController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final bloodRequestRepo = ref.read(bloodRequestRepositoryProvider);

    final data = {
      'uid': uid,
      'name': _nameController.text.trim(),
      'bloodGroup': _selectedBloodGroup!,
      'bag': _selectedBag!,
      'address': _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'locationAddress': _locationAddress,
      'geohash': (_latitude != null && _longitude != null)
          ? Geohash.encode(_latitude!, _longitude!)
          : null,
      'mobile': PhoneUtils.toCanonical(_mobileController.text.trim()),
      'note': _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      'date': DateFormat('d/M/yyy').format(_selectedDate!),
      'time': _selectedTime!.format(context),
      'status': _status,
    };

    try {
      setState(() => _isLoading = true);

      if (_isEditing) {
        await bloodRequestRepo.updateRequest(widget.existingRequest!.id, data);
      } else {
        data['createdAt'] = DateTime.now();
        data['id'] = '';
        await bloodRequestRepo.createRequest(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Request updated!' : 'Request posted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                PhosphorIcons.drop,
                color: Colors.red.shade600,
                size: 18.w,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              _isEditing ? 'Edit Blood Request' : 'Post Blood Request',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  color: theme.colorScheme.surface,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(PhosphorIcons.flag,
                                size: 20.w, color: Colors.red.shade400),
                            SizedBox(width: 8.w),
                            Text(
                              'Request Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'active',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 18.w, color: Colors.green),
                                  SizedBox(width: 8.w),
                                  const Text('Active'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fulfilled',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 18.w, color: Colors.blue),
                                  SizedBox(width: 8.w),
                                  const Text('Fulfilled'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel,
                                      size: 18.w, color: Colors.red),
                                  SizedBox(width: 8.w),
                                  const Text('Cancelled'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Save the form below to apply the status change.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
              ],
              RequestForm(
                nameController: _nameController,
                mobileController: _mobileController,
                addressController: _addressController,
                noteController: _noteController,
                selectedBloodGroup: _selectedBloodGroup,
                selectedBag: _selectedBag,
                bagOptions: _bagOptions,
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                isLoading: _isLoading,
                onSubmit: _submit,
                isEditing: _isEditing,
                hasChanges: _hasChanges,
                onBloodGroupChanged: (v) =>
                    setState(() => _selectedBloodGroup = v),
                onBagChanged: (v) => setState(() => _selectedBag = v),
                onDateChanged: (v) => setState(() => _selectedDate = v),
                onTimeChanged: (v) => setState(() => _selectedTime = v),
                selectedLatitude: _latitude,
                selectedLongitude: _longitude,
                locationAddress: _locationAddress,
                onLocationPicked: (lat, lng, address) => setState(() {
                  _latitude = lat;
                  _longitude = lng;
                  _locationAddress = address;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
