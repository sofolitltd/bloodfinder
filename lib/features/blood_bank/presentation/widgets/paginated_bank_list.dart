import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/blood_bank.dart';
import 'blood_bank_card.dart';

class PaginatedBankList extends StatelessWidget {
  final List<BloodBank> banks;
  final bool isLoading;
  final bool hasMore;
  final ScrollController scrollController;
  final String emptyMessage;
  final double paddingBottom;

  const PaginatedBankList({
    super.key,
    required this.banks,
    required this.isLoading,
    required this.hasMore,
    required this.scrollController,
    this.emptyMessage = 'No blood banks found',
    this.paddingBottom = 96,
  });

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (banks.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.hospital, size: 48.w, color: Colors.grey.shade300),
            SizedBox(height: 8.h),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, paddingBottom.h),
      itemCount: banks.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= banks.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: BloodBankCard(bloodBank: banks[index]),
        );
      },
    );
  }
}
