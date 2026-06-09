import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/blood_request.dart';
import '../models/blood_request_with_user.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/repository_providers.dart';

final bloodRequestsWithUsersProvider =
    StreamProvider<List<BloodRequestWithUser>>((ref) {
      final auth = ref.watch(authRepositoryProvider);
      final currentUser = auth.currentUser;
      if (currentUser == null) return const Stream.empty();

      final requestRepo = ref.watch(bloodRequestRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      return requestRepo.userRequestsStream(currentUser.uid).asyncMap((snapshot) async {
        final requests = snapshot.docs
            .map((doc) => BloodRequest.fromFirestore(doc))
            .toList();

        if (requests.isEmpty) return <BloodRequestWithUser>[];

        final uids = requests.map((r) => r.uid).toList();
        final userSnapshot = await userRepo.getUsersByIds(uids);
        final userMap = {
          for (final doc in userSnapshot.docs)
            doc.id: UserModel.fromJson(doc.data()),
        };

        return requests
            .where((r) => userMap.containsKey(r.uid))
            .map((r) => BloodRequestWithUser(request: r, user: userMap[r.uid]!))
            .toList();
      });
    });

final districtRequestsWithUsersProvider =
    StreamProvider.family<List<BloodRequestWithUser>, String>((ref, district) {
      final requestRepo = ref.watch(bloodRequestRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      return requestRepo.requestsByDistrict(district).asyncMap((snapshot) async {
        final requests = snapshot.docs
            .map((doc) => BloodRequest.fromFirestore(doc))
            .toList();

        if (requests.isEmpty) return <BloodRequestWithUser>[];

        final uids = requests.map((r) => r.uid).toList();
        final userSnapshot = await userRepo.getUsersByIds(uids);
        final userMap = {
          for (final doc in userSnapshot.docs)
            doc.id: UserModel.fromJson(doc.data()),
        };

        return requests
            .where((r) => userMap.containsKey(r.uid))
            .map((r) => BloodRequestWithUser(request: r, user: userMap[r.uid]!))
            .toList();
      });
    });
