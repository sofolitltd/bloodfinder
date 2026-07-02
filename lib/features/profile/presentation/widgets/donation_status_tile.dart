import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DonationStatusTile extends StatefulWidget {
  final String uid;
  final String availability;
  final DateTime? snoozedUntil;
  final dynamic userRepo;

  const DonationStatusTile({
    super.key,
    required this.uid,
    required this.availability,
    this.snoozedUntil,
    required this.userRepo,
  });

  @override
  State<DonationStatusTile> createState() => _DonationStatusTileState();
}

class _DonationStatusTileState extends State<DonationStatusTile> {
  late String _selected;
  DateTime? _snoozeUntil;

  static const _options = [
    ('available', 'Available', Icons.check_circle, Colors.green),
    ('out_of_city', 'Out of City', Icons.flight_takeoff, Colors.orange),
    ('unavailable', "Can't Donate", Icons.block, Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.availability;
    _snoozeUntil = widget.snoozedUntil;
  }

  Future<void> _updateAvailability(String value) async {
    if (value == _selected) return;

    final labels = {
      'available': 'Available',
      'out_of_city': 'Out of City',
      'unavailable': "Can't Donate",
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('Change Donation Status'),
        content: Text('Switch your status to "${labels[value]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _selected = value);

    final data = <String, dynamic>{'availability': value};
    if (value != 'unavailable') {
      data['snoozedUntil'] = FieldValue.delete();
      _snoozeUntil = null;
    }

    await widget.userRepo.updateUser(widget.uid, data);
    if (!mounted) return;
    setState(() {});

    if (value == 'unavailable') {
      _showSnoozePicker();
    }
  }

  Future<void> _showSnoozePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    setState(() => _snoozeUntil = date);
    await widget.userRepo.updateUser(widget.uid, {
      'snoozedUntil': Timestamp.fromDate(date),
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _options.firstWhere(
      (o) => o.$1 == _selected,
      orElse: () => _options[0],
    );

    return Container(
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(current.$3, size: 18, color: current.$4),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation Status',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_snoozeUntil != null)
                      Text(
                        'Snoozed until ${DateFormat.yMMMd().format(_snoozeUntil!)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              spacing: 6,
              children: _options.map((opt) {
                final selected = opt.$1 == _selected;
                return GestureDetector(
                  onTap: () => _updateAvailability(opt.$1),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? opt.$4.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: selected
                            ? opt.$4
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.$3, size: 14, color: selected ? opt.$4 : Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? opt.$4 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
