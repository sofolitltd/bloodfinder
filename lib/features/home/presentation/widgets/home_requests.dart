import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../blood_request/models/blood_request.dart';
import '../../../../shared/widgets/blood_request_card.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../data/providers/user_providers.dart';
import '../../../../routes/app_route.dart';

final _homeRequestsProvider = FutureProvider.autoDispose
    .family<List<BloodRequest>, double?>((ref, radius) async {
  final feedRepo = ref.read(feedRepositoryProvider);
  final user = ref.watch(userProvider).value;
  final snapshot = await feedRepo.getRequests(
    latitude: user?.latitude,
    longitude: user?.longitude,
    radiusInKm: radius,
    limit: 3,
  );
  return snapshot.docs.map((d) => BloodRequest.fromFirestore(d)).toList();
});

class HomeBloodRequestsSection extends ConsumerWidget {
  const HomeBloodRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final requestsAsync = ref.watch(_homeRequestsProvider(50.0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.warningCircle,
                      color: Colors.red.shade500,
                      size: 22,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Near You',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Immediate blood needs in your area',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.goNamed(AppRoute.feed.name),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          requestsAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.drop, size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No urgent requests nearby',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final user = ref.watch(userProvider).value;
              final userLat = user?.latitude;
              final userLng = user?.longitude;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  double? distance;
                  if (userLat != null && userLng != null && req.latitude != null && req.longitude != null) {
                    distance = _haversineDistance(userLat, userLng, req.latitude!, req.longitude!);
                  }
                  return BloodRequestCard(
                    request: req,
                    embedded: true,
                    distanceInKm: distance,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.asin(math.sqrt(a));
  return (R * c * 10).roundToDouble() / 10;
}

double _degreesToRadians(double degrees) => degrees * (3.141592653589793 / 180);
