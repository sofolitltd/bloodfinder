
import '../../../data/repositories/user_repository.dart';

const _badgeTiers = [
  (1, 'first_hero'),
  (3, 'bronze'),
  (7, 'silver'),
  (15, 'gold'),
  (25, 'legend'),
];

List<String> computeBadges(int count) {
  return _badgeTiers.where((t) => count >= t.$1).map((t) => t.$2).toList();
}

String badgeLabel(String badge) {
  switch (badge) {
    case 'first_hero':
      return 'First Hero';
    case 'bronze':
      return 'Bronze Donor';
    case 'silver':
      return 'Silver Donor';
    case 'gold':
      return 'Gold Donor';
    case 'legend':
      return 'Legend';
    default:
      return badge;
  }
}

class DonationService {
  DonationService(this._userRepo);

  final UserRepository _userRepo;

  Future<void> onDonationConfirmed(String uid) async {
    final doc = await _userRepo.getUser(uid);
    final data = doc.data() as Map<String, dynamic>;
    final currentCount = (data['donationCount'] as num?)?.toInt() ?? 0;
    final newCount = currentCount + 1;

    final currentBadges =
        (data['badges'] as List<dynamic>?)?.cast<String>() ?? [];
    final newBadges = computeBadges(newCount);

    final newBadgeEarned = newBadges.length > currentBadges.length;
    final newBadgeName = newBadgeEarned
        ? badgeLabel(newBadges.last)
        : null;

    final updates = <String, dynamic>{
      'donationCount': newCount,
      'badges': newBadges,
    };

    if (newCount == 1) {
      updates['isVerifiedDonor'] = true;
    }

    await _userRepo.updateUser(uid, updates);

    if (newBadgeEarned && newBadgeName != null) {
      _lastEarnedBadge = newBadgeName;
      _lastCount = newCount;
    }
  }

  String? _lastEarnedBadge;
  int? _lastCount;

  String? get lastEarnedBadge => _lastEarnedBadge;
  int? get lastCount => _lastCount;
}
