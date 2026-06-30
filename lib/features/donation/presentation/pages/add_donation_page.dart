import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../services/donation_service.dart';
import 'certificate_page.dart';

class AddDonationPage extends ConsumerStatefulWidget {
  const AddDonationPage({super.key});

  @override
  ConsumerState<AddDonationPage> createState() => _AddDonationPageState();
}

class _AddDonationPageState extends ConsumerState<AddDonationPage> {
  DateTime? _selectedDate;
  final _recipientNameController = TextEditingController();
  final _recipientMobileController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();
  final _waitingDaysController = TextEditingController();
  String _donationType = 'whole_blood';
  XFile? _pickedImage;
  bool _isLoading = false;

  static const _donationTypes = [
    ('whole_blood', 'Whole Blood', 90),
    ('platelets', 'Platelets', 14),
    ('plasma', 'Plasma', 28),
    ('double_red', 'Double Red Cells', 150),
  ];

  @override
  void initState() {
    super.initState();
    _waitingDaysController.text = '90';
  }

  void _updateWaitingDays(String type) {
    final match = _donationTypes.firstWhere((t) => t.$1 == type);
    _waitingDaysController.text = match.$3.toString();
  }

  Future<void> _pickDonationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    final compressed = await _compressImage(File(file.path));
    if (!mounted) return;
    setState(() => _pickedImage = compressed ?? file);
  }

  Future<XFile?> _compressImage(File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final isPng = ext == 'png';
      final targetPath =
          '${file.parent.path}/donation_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50,
        minWidth: 300,
        minHeight: 300,
        format: isPng ? CompressFormat.png : CompressFormat.jpeg,
      );
      return result != null ? XFile(result.path) : null;
    } catch (_) {
      return null;
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file, String uid) async {
    try {
      final storageRepo = ref.read(storageRepositoryProvider);
      final path = 'donations/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await storageRepo.uploadFile(file, path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDonation() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a donation date.')),
      );
      return;
    }

    if (_recipientNameController.text.trim().isEmpty ||
        _recipientMobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name and mobile.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No user logged in.')));
        return;
      }

      final userRepo = ref.read(userRepositoryProvider);

      // Upload image first if picked
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(File(_pickedImage!.path), user.uid);
      }

      final typeData = _donationTypes.firstWhere((t) => t.$1 == _donationType);
      final waitingDays = int.tryParse(_waitingDaysController.text.trim()) ?? typeData.$3;
      await userRepo.addDonation(user.uid, {
        'donationDate': _selectedDate,
        'recipientName': _recipientNameController.text.trim(),
        'recipientMobile': _recipientMobileController.text.trim(),
        'donationType': _donationType,
        'donationTypeLabel': typeData.$2,
        'waitingDays': waitingDays,
        'hospitalName': _hospitalController.text.trim().isEmpty
            ? null
            : _hospitalController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final service = DonationService(userRepo);
      await service.onDonationConfirmed(user.uid);

      if (!mounted) return;

      final userAsync = ref.read(userProvider);
      final userModel = userAsync.value;

      if (userModel != null) {
        final doc = await userRepo.getUser(user.uid);
        final data = doc.data() as Map<String, dynamic>;
        final count = (data['donationCount'] as num?)?.toInt() ?? 1;
        final badges = (data['badges'] as List<dynamic>?)?.cast<String>() ?? [];
        final badge =
            badges.isNotEmpty ? badgeLabel(badges.last) : 'First Hero';

          Navigator.pop(context, true);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CertificatePage(
                user: userModel,
                donationCount: count,
                badgeName: badge,
                donationImageUrl: imageUrl,
              ),
            ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add donation.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientMobileController.dispose();
    _hospitalController.dispose();
    _notesController.dispose();
    _waitingDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText = _selectedDate == null
        ? 'Select Date'
        : DateFormat('dd MMMM, yyyy').format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Donation'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Donation Details ──
            _buildSectionHeader(PhosphorIcons.drop, 'Donation Details'),
            SizedBox(height: 6.h),
            _buildSectionCard(
              Column(
                children: [
                  _buildDateTile(selectedDateText),
                  SizedBox(height: 12.h),
                  _buildDonationTypeDropdown(),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _waitingDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Eligible After (days)',
                      hintText: 'e.g., 90',
                      prefixIcon: Icon(PhosphorIcons.clockCountdown, size: 20.w),
                      border: const OutlineInputBorder(),
                      helperText: 'Standard: 56–120 days. Check local guidelines.',
                      helperMaxLines: 2,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _hospitalController,
                    decoration: InputDecoration(
                      labelText: 'Hospital / Clinic',
                      hintText: 'e.g., Dhaka Medical College',
                      prefixIcon:
                          Icon(PhosphorIcons.hospital, size: 20.w),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Recipient Info ──
            _buildSectionHeader(PhosphorIcons.user, 'Recipient Info'),
            SizedBox(height: 6.h),
            _buildSectionCard(
              Column(
                children: [
                  TextField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _recipientMobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Mobile *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Memories ──
            _buildSectionHeader(PhosphorIcons.camera, 'Memories'),
            SizedBox(height: 6.h),
            _buildSectionCard(
              Column(
                spacing: 10.h,
                children: [
                  _buildImagePicker(),

                  //
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Any memories or notes about this donation...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveDonation,
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add Donation',
                        style:
                            TextStyle(fontSize: 16.sp, color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  // ── Reusable section helpers ──

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon, size: 20, color: Colors.red.shade600),
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateTile(String text) {
    return InkWell(
      onTap: _pickDonationDate,
      borderRadius: BorderRadius.circular(8.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Donation Date *',
          prefixIcon: Icon(PhosphorIcons.calendar, size: 20.w),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
    );
  }

  Widget _buildDonationTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _donationType,
      decoration: InputDecoration(
        labelText: 'Donation Type',
        prefixIcon: Icon(PhosphorIcons.drop, size: 20.w),
        border: const OutlineInputBorder(),
      ),
      items: _donationTypes.map((t) {
        return DropdownMenuItem(
          value: t.$1,
          child: Text(t.$2),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() => _donationType = v);
          _updateWaitingDays(v);
        }
      },
    );
  }

  Widget _buildImagePicker() {
    if (_pickedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              File(_pickedImage!.path),
              height: 180.h,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _pickedImage = null),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.x,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.shade200, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          children: [
            Icon(PhosphorIcons.camera, size: 28, color: Colors.red.shade400),
            SizedBox(height: 8.h),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
