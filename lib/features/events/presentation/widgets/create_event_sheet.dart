import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/geohash.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../shared/widgets/map_location_picker_page.dart';
import '../../models/blood_event.dart';

void showCreateEventSheet(BuildContext context, WidgetRef ref,
    {BloodEvent? event}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CreateEventSheet(ref: ref, event: event),
  );
}

class _CreateEventSheet extends StatefulWidget {
  final WidgetRef ref;
  final BloodEvent? event;

  _CreateEventSheet({required this.ref, this.event});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _endDate;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  XFile? _image;
  bool _imageChanged = false;
  bool _loading = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _titleController.text = e.title;
      _descController.text = e.description;
      _eventDate = e.eventDate;
      _eventTime = TimeOfDay.fromDateTime(e.eventDate);
      _endDate = e.endDate;
      _latitude = e.latitude;
      _longitude = e.longitude;
      _locationAddress = e.locationAddress;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _image = file;
        _imageChanged = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _eventDate ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: _eventDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) setState(() => _eventTime = time);
  }

  Future<void> _pickLocation() async {
    final user = widget.ref.read(userProvider).value;
    final result = await MapLocationPickerPage.show(
      context,
      initialLatitude: _latitude ?? user?.latitude,
      initialLongitude: _longitude ?? user?.longitude,
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationAddress = result.displayAddress;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null || _eventTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time.')),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = widget.ref.read(userProvider).value;
      final uid = user?.uid ?? '';
      final userName = user != null
          ? '${user.firstName} ${user.lastName}'.trim()
          : '';
      final storage = widget.ref.read(storageRepositoryProvider);
      final repo = widget.ref.read(eventRepositoryProvider);

      String? imageUrl = widget.event?.imageUrl;
      if (_imageChanged && _image != null) {
        imageUrl = await storage.uploadFile(
          File(_image!.path),
          'events/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final eventDt = DateTime(
        _eventDate!.year,
        _eventDate!.month,
        _eventDate!.day,
        _eventTime!.hour,
        _eventTime!.minute,
      );

      final data = {
        'title': _titleController.text.trim(),
        'organizerName': userName,
        'organizerUid': uid,
        'description': _descController.text.trim(),
        'latitude': _latitude!,
        'longitude': _longitude!,
        'geohash': Geohash.encode(_latitude!, _longitude!),
        'locationAddress': _locationAddress ?? '',
        'eventDate': eventDt,
        'imageUrl': imageUrl,
        if (!_isEditing) 'createdAt': DateTime.now(),
        if (_endDate != null) 'endDate': DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _eventTime!.hour,
          _eventTime!.minute,
        ),
      };

      if (_isEditing) {
        await repo.updateEvent(widget.event!.id, data);
      } else {
        data['rsvpCount'] = 0;
        await repo.createEvent(data);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Event updated!' : 'Event created!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Failed to update event: $e' : 'Failed to create event: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = _eventDate != null
        ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
        : 'Select Date';
    final endDateText = _endDate != null
        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
        : 'End Date (optional)';
    final timeText = _eventTime != null
        ? _eventTime!.format(context)
        : 'Select Time';
    final locText = _locationAddress ?? 'Select Location';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.w,
        right: 16.w,
        top: 16.h,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Event' : 'Create Event',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today, size: 18.w),
                      label:
                          Text(dateText, style: TextStyle(fontSize: 13.sp)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: Icon(Icons.access_time, size: 18.w),
                      label:
                          Text(timeText, style: TextStyle(fontSize: 13.sp)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: _pickEndDate,
                icon: Icon(Icons.date_range, size: 18.w),
                label: Text(endDateText,
                    style: TextStyle(fontSize: 13.sp)),
              ),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: Icon(Icons.location_on, size: 18.w),
                label: Text(locText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.sp)),
              ),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image, size: 18.w),
                label: Text(
                  _image != null || widget.event?.imageUrl != null
                      ? 'Image selected'
                      : 'Add Cover Image',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ),
              SizedBox(height: 20.h),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Create Event'),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
