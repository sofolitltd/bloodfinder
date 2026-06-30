import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/widgets/start_chat_btn.dart';
import '../../../../shared/widgets/admin_widget.dart';
import '../../../chat/models/chat_model.dart';
import 'add_emergency_donor_page.dart';

const _pageSize = 15;

class EmergencyDonorPage extends ConsumerStatefulWidget {
  const EmergencyDonorPage({super.key});

  @override
  ConsumerState<EmergencyDonorPage> createState() => _EmergencyDonorPageState();
}

class _EmergencyDonorPageState extends ConsumerState<EmergencyDonorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<UserModel> _nearbyDonors = [];
  DocumentSnapshot<Map<String, dynamic>>? _nearbyLastDoc;
  bool _nearbyLoading = false;
  bool _nearbyHasMore = true;
  late ScrollController _nearbyScrollCtrl;

  final List<UserModel> _allDonors = [];
  DocumentSnapshot<Map<String, dynamic>>? _allLastDoc;
  bool _allLoading = false;
  bool _allHasMore = true;
  late ScrollController _allScrollCtrl;

  Position? _position;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nearbyScrollCtrl = ScrollController()..addListener(_onNearbyScroll);
    _allScrollCtrl = ScrollController()..addListener(_onAllScroll);
    _initLocation();
    _loadAllDonors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nearbyScrollCtrl.dispose();
    _allScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = pos);
        _loadNearbyDonors();
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadNearbyDonors() async {
    if (_nearbyLoading || !_nearbyHasMore || _position == null) return;
    setState(() => _nearbyLoading = true);

    final repo = ref.read(userRepositoryProvider);
    try {
      final snap = await repo.getPaginatedEmergencyDonorsByProximity(
        _position!.latitude,
        _position!.longitude,
        20.0,
        _pageSize,
        startAfter: _nearbyLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _nearbyHasMore = snap.docs.length >= _pageSize;
        _nearbyLastDoc =
            snap.docs.isNotEmpty ? snap.docs.last : _nearbyLastDoc;
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['availability'] == 'unavailable') continue;
          _nearbyDonors.add(UserModel.fromJson({'uid': doc.id, ...data}));
        }
        _nearbyLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  Future<void> _loadAllDonors() async {
    if (_allLoading || !_allHasMore) return;
    setState(() => _allLoading = true);

    final repo = ref.read(userRepositoryProvider);
    try {
      final snap = await repo.getPaginatedEmergencyDonors(
        _pageSize,
        startAfter: _allLastDoc,
      );
      if (!mounted) return;
      setState(() {
        _allHasMore = snap.docs.length >= _pageSize;
        _allLastDoc = snap.docs.isNotEmpty ? snap.docs.last : _allLastDoc;
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['availability'] == 'unavailable') continue;
          _allDonors.add(UserModel.fromJson({'uid': doc.id, ...data}));
        }
        _allLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _allLoading = false);
    }
  }

  void _onNearbyScroll() {
    if (_nearbyScrollCtrl.position.pixels >=
        _nearbyScrollCtrl.position.maxScrollExtent - 200) {
      _loadNearbyDonors();
    }
  }

  void _onAllScroll() {
    if (_allScrollCtrl.position.pixels >=
        _allScrollCtrl.position.maxScrollExtent - 200) {
      _loadAllDonors();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                PhosphorIcons.ambulance,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
            SizedBox(width: 10.w),
            const Text(
              'Emergency Donors',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red.shade700,
          tabs: const [
            Tab(text: 'Nearby'),
            Tab(text: 'All Donors'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNearbyTab(),
                _buildAllTab(),
              ],
            ),
          ),
          AdminWidget(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEmergencyDonorPage(),
                    ),
                  );
                },
                icon: Icon(PhosphorIcons.plusBold, size: 20.w),
                label: Text(
                  'Manage Emergency Donors',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab() {
    if (_position == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.mapPinLine, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text(
              'Enable location to see nearby donors',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    if (_nearbyDonors.isEmpty && _nearbyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nearbyDonors.isEmpty && !_nearbyLoading) {
      return _emptyState();
    }
    return ListView.builder(
      controller: _nearbyScrollCtrl,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      itemCount: _nearbyDonors.length + (_nearbyHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _nearbyDonors.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _DonorCard(donor: _nearbyDonors[index]),
        );
      },
    );
  }

  Widget _buildAllTab() {
    if (_allDonors.isEmpty && _allLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allDonors.isEmpty && !_allLoading) {
      return _emptyState();
    }
    return ListView.builder(
      controller: _allScrollCtrl,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      itemCount: _allDonors.length + (_allHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allDonors.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _DonorCard(donor: _allDonors[index]),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              PhosphorIcons.ambulance,
              size: 34,
              color: Colors.red.shade300,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No emergency donors',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Check back later or add yourself\nas an emergency donor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final UserModel donor;

  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDonorDialog(context, donor),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
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
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: Colors.red.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: donor.image.isEmpty
                    ? Center(
                        child: Text(
                          donor.firstName.isNotEmpty
                              ? donor.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: donor.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Center(
                          child: Icon(
                            PhosphorIcons.user,
                            color: Colors.red.shade300,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${donor.firstName} ${donor.lastName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            donor.bloodGroup,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(PhosphorIcons.phone,
                            size: 14, color: Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Text(
                          donor.mobileNumber,
                          style: TextStyle(
                              fontSize: 13.sp, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(PhosphorIcons.mapPin,
                            size: 14, color: Colors.grey.shade400),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            donor.locationAddress ?? 'Location not set',
                            style: TextStyle(
                                fontSize: 13.sp, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _MiniButton(
                          icon: PhosphorIcons.phoneCall,
                          label: 'Call',
                          color: Colors.green.shade600,
                          onTap: () => _callDonor(donor.mobileNumber),
                        ),
                        SizedBox(width: 8.w),
                        _MiniChatButton(otherUserId: donor.uid),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _callDonor(String mobile) async {
    if (mobile.isEmpty) return;
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

void _showDonorDialog(BuildContext context, UserModel donor) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: _DonorDetailDialog(donor: donor),
    ),
  );
}

class _DonorDetailDialog extends StatelessWidget {
  final UserModel donor;

  const _DonorDetailDialog({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 28.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade800,
                Colors.red.shade600,
                Colors.red.shade400,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.xBold,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Stack(
                children: [
                  Container(
                    width: 72.w,
                    height: 72.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: donor.image.isEmpty
                        ? Center(
                            child: Text(
                              donor.firstName.isNotEmpty
                                  ? donor.firstName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: donor.image,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        donor.bloodGroup,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                '${donor.firstName} ${donor.lastName}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Emergency Donor',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _DetailTile(
                icon: PhosphorIcons.phoneCall,
                label: 'Phone',
                value: donor.mobileNumber,
              ),
              SizedBox(height: 12.h),
              _DetailTile(
                icon: PhosphorIcons.mapPin,
                label: 'Location',
                value: donor.locationAddress ?? 'Not set',
              ),
              SizedBox(height: 12.h),
              _DetailTile(
                icon: PhosphorIcons.genderIntersex,
                label: 'Gender',
                value: donor.gender,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callDonor(context, donor.mobileNumber);
                        },
                        icon: Icon(PhosphorIcons.phoneCall, size: 18.w),
                        label: Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(elevation: 0),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: StartChatButton(
                        otherUserId: donor.uid,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _callDonor(BuildContext context, String mobile) async {
    if (mobile.isEmpty) return;
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18, color: Colors.red.shade600),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChatButton extends ConsumerStatefulWidget {
  final String otherUserId;

  const _MiniChatButton({required this.otherUserId});

  @override
  ConsumerState<_MiniChatButton> createState() => _MiniChatButtonState();
}

class _MiniChatButtonState extends ConsumerState<_MiniChatButton> {
  bool _isLoading = false;

  Future<void> _startChat() async {
    setState(() => _isLoading = true);

    try {
      final currentUserID = ref.read(authRepositoryProvider).currentUser!.uid;
      final communityRepo = ref.read(communityRepositoryProvider);

      final existingChats = await communityRepo.getExistingChat(
        currentUserID,
        widget.otherUserId,
      );

      DocumentSnapshot<Map<String, dynamic>>? chatDoc;
      if (existingChats.isNotEmpty) {
        chatDoc = existingChats.first;
      }

      if (chatDoc == null) {
        final emptyMsg = MessageModel(
          id: '',
          senderId: '',
          text: 'Hi! Feel free to send your first message.',
          timestamp: DateTime.now(),
          seenBy: [],
        );

        final newChatRef = await communityRepo.addChat({
          'participants': [currentUserID, widget.otherUserId],
          'lastMessage': emptyMsg.toMap(),
          'lastTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'archivedBy': [],
          'deletedBy': [],
        });
        chatDoc = await newChatRef.get();
      }

      if (mounted) {
        GoRouter.of(context).push(
          '/chats/${chatDoc.id}',
          extra: {'donorId': currentUserID, 'requesterId': widget.otherUserId},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserID = ref.read(authRepositoryProvider).currentUser!.uid;
    final isSelf = widget.otherUserId == currentUserID;

    return InkWell(
      onTap: isSelf || _isLoading ? null : _startChat,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: _isLoading
            ? SizedBox(
                width: 14.w,
                height: 14.h,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.chatDots,
                    size: 14,
                    color: isSelf ? Colors.grey : Colors.blue.shade600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    isSelf ? 'Chat' : 'Chat',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSelf ? Colors.grey : Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Future<void> callDonor(String mobile) async {
  if (mobile.isEmpty) return;
  final Uri uri = Uri.parse('tel:$mobile');
  try {
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) debugPrint('Could not launch dialer for $mobile');
  } catch (e) {
    debugPrint('Error launching dialer: $e');
  }
}
