import 'dart:math';

import 'package:bloodfinder/data/models/user_model.dart';
import 'package:bloodfinder/features/blood_bank/models/blood_bank.dart';
import 'package:bloodfinder/features/community/models/community.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../data/providers/repository_providers.dart';
import '../../../blood_bank/presentation/pages/blood_bank_detail_page.dart';

class FindDonorPage extends ConsumerStatefulWidget {
  final String bloodGroup;
  final double latitude;
  final double longitude;
  final double radiusInKm;

  const FindDonorPage({
    super.key,
    required this.bloodGroup,
    required this.latitude,
    required this.longitude,
    required this.radiusInKm,
  });

  @override
  ConsumerState<FindDonorPage> createState() => _FindDonorPageState();
}

class _FindDonorPageState extends ConsumerState<FindDonorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _donors = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDonors();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchDonors();
      }
    });
  }

  Future<void> _fetchDonors() async {
    if (!_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final stream = ref.read(userRepositoryProvider).usersByDonors(
            bloodGroup: widget.bloodGroup,
            latitude: widget.latitude,
            longitude: widget.longitude,
            radiusInKm: widget.radiusInKm,
            limit: _pageSize,
            startAfter: _lastDoc as DocumentSnapshot<Map<String, dynamic>>?,
          );

      final snapshot = await stream.first;

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _donors.addAll(
          snapshot.docs
              .where((doc) =>
                  (doc.data()['availability'] as String?) != 'unavailable')
              .map((e) => e.data())
              .toList(),
        );
      }
      if (snapshot.docs.length < _pageSize) _hasMore = false;

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching donors: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bloodGroup} Donors nearby'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: Theme.of(context).colorScheme.primary,
                     tabs: const [
            Tab(text: 'Donors'),
            Tab(text: 'Communities'),
            Tab(text: 'Blood Banks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonorsTab(),
          _buildCommunitiesTab(),
          _buildBloodBankTab(),
        ],
      ),
    );
  }

  Widget _buildDonorsTab() {
    if (_donors.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_donors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No ${widget.bloodGroup} donors found\nwithin ${widget.radiusInKm.round()} km',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
          ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _donors.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == _donors.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildDonorListItem(
            donor: UserModel.fromJson(_donors[index]));
      },
    );
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  Widget _buildCommunitiesTab() {
    final repo = ref.read(communityRepositoryProvider);
    final stream = repo.communitiesByBloodGroupStream(
      widget.bloodGroup,
      widget.latitude,
      widget.longitude,
      widget.radiusInKm,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No communities with ${widget.bloodGroup}\ndonors found within ${widget.radiusInKm.round()} km',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final community = Community.fromJson({
              ...docs[index].data(),
              'id': docs[index].id,
            });
            final count = community.bloodGroupCounts?[widget.bloodGroup] ?? 0;

            double? distance;
            if (community.latitude != null && community.longitude != null) {
              distance = _haversineDistance(
                widget.latitude,
                widget.longitude,
                community.latitude!,
                community.longitude!,
              );
            }

            return _buildCommunityCard(community, count, distance);
          },
        );
      },
    );
  }

  Widget _buildCommunityCard(Community community, int count, double? distance) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'communityDetail',
          pathParameters: {'communityId': community.id},
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: community.images.isEmpty
                    ? Text(
                        community.name.isNotEmpty
                            ? community.name[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: community.images.first,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (community.locationAddress != null &&
                        community.locationAddress!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin,
                            size: 13,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              community.locationAddress!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: count > 0
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count ${widget.bloodGroup} donor${count == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: count > 0
                                  ? Colors.red.shade700
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  PhosphorIcons.caretRight,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodBankTab() {
    final repo = ref.read(bloodBankRepositoryProvider);
    final stream = repo.banksByProximityStream(
      widget.latitude,
      widget.longitude,
      widget.radiusInKm,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_hospital,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No blood banks found\nwithin ${widget.radiusInKm.round()} km',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final bank = BloodBank.fromJson({
              ...docs[index].data(),
              'id': docs[index].id,
            });

            double? distance;
            if (bank.latitude != null && bank.longitude != null) {
              distance = _haversineDistance(
                widget.latitude,
                widget.longitude,
                bank.latitude!,
                bank.longitude!,
              );
            }

            return _buildBloodBankCard(bank, distance);
          },
        );
      },
    );
  }

  Widget _buildBloodBankCard(BloodBank bank, double? distance) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BloodBankDetailPage(bloodBank: bank),
          ),
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: bank.imageUrl != null && bank.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bank.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const CupertinoActivityIndicator(),
                        errorWidget: (_, _, _) => Icon(
                          Icons.local_hospital,
                          color: Colors.red.shade200,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.local_hospital,
                        color: Colors.red.shade200,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (bank.locationAddress != null &&
                        bank.locationAddress!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.mapPin,
                            size: 13,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              bank.locationAddress!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (bank.mobile1.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bank.mobile1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  PhosphorIcons.caretRight,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonorListItem({required UserModel donor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final distance = donor.latitude != null && donor.longitude != null
        ? _haversineDistance(
            widget.latitude,
            widget.longitude,
            donor.latitude!,
            donor.longitude!,
          )
        : null;
    final isVerified = _donors
            .firstWhere((d) => d['uid'] == donor.uid)['isVerifiedDonor']
                as bool? ??
        false;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.shade50,
              ),
              clipBehavior: Clip.antiAlias,
              child: donor.image.isEmpty
                  ? Center(
                      child: Text(
                        donor.firstName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: donor.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const CupertinoActivityIndicator(),
                      errorWidget: (_, __, ___) => Icon(
                        PhosphorIcons.warningCircle,
                        color: Colors.red.shade200,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${donor.firstName} ${donor.lastName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue.shade400,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (donor.locationAddress != null &&
                      donor.locationAddress!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.mapPin,
                          size: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            donor.locationAddress!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                if (distance != null) const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade500],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    donor.bloodGroup,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
