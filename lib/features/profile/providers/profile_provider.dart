import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/providers/user_providers.dart';

class ProfileDonationInfo {
  final int lifeSavedCount;
  final String nextDonationText;
  final String nextDonationDay;
  final String nextDonationMonth;
  final bool isEligible;

  const ProfileDonationInfo({
    this.lifeSavedCount = 0,
    this.nextDonationText = 'Your Next',
    this.nextDonationDay = '-',
    this.nextDonationMonth = '',
    this.isEligible = false,
  });
}

final profileDonationInfoProvider =
    Provider<ProfileDonationInfo>((ref) {
  final donationAsync = ref.watch(donationProvider);
  final donations = donationAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <DocumentSnapshot>[],
  );

  final lifeSavedCount = donations.length;
  DateTime? lastDonationDate;

  if (donations.isNotEmpty) {
    final donationData = donations.first.data() as Map<String, dynamic>;
    final donationDateTimestamp =
        donationData['donationDate'] as Timestamp?;
    if (donationDateTimestamp != null) {
      lastDonationDate = donationDateTimestamp.toDate();
    }
  }

  String nextDonationText = 'Your Next';
  String nextDonationDay = '-';
  String nextDonationMonth = '';
  bool isEligible = false;

  if (lastDonationDate != null) {
    final nextDonation = DateTime(
      lastDonationDate.year,
      lastDonationDate.month + 3,
      lastDonationDate.day,
    );
    if (nextDonation.isBefore(DateTime.now())) {
      isEligible = true;
      nextDonationText = 'Tap to donate';
      nextDonationDay = 'Eligible';
      nextDonationMonth = '';
    } else {
      nextDonationText = 'Next Donation';
      nextDonationDay = DateFormat('dd').format(nextDonation);
      nextDonationMonth = DateFormat('MMM').format(nextDonation);
    }
  }

  return ProfileDonationInfo(
    lifeSavedCount: lifeSavedCount,
    nextDonationText: nextDonationText,
    nextDonationDay: nextDonationDay,
    nextDonationMonth: nextDonationMonth,
    isEligible: isEligible,
  );
});
