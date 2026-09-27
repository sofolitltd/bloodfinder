import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/providers/repository_providers.dart';
import '../../../../shared/widgets/start_chat_btn.dart';

class DonorDetailPage extends ConsumerStatefulWidget {
  final UserModel donor;
  final double? finderLatitude;
  final double? finderLongitude;
  final bool isVerified;
  final String? availability;

  const DonorDetailPage({
    super.key,
    required this.donor,
    this.finderLatitude,
    this.finderLongitude,
    this.isVerified = false,
    this.availability,
  });

  @override
  ConsumerState<DonorDetailPage> createState() => _DonorDetailPageState();
}

class _DonorDetailPageState extends ConsumerState<DonorDetailPage> {
  final MapController _mapController = MapController();

  bool get _hasBothLocations =>
      widget.donor.latitude != null &&
      widget.donor.longitude != null &&
      widget.finderLatitude != null &&
      widget.finderLongitude != null;

  void _fitMapToMarkers() {
    if (!_hasBothLocations) return;
    final donorPoint = LatLng(widget.donor.latitude!, widget.donor.longitude!);
    final finderPoint = LatLng(widget.finderLatitude!, widget.finderLongitude!);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(donorPoint, finderPoint),
        padding: EdgeInsets.all(48.w),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = widget.donor;
    final isVerified = widget.isVerified;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
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
                  bottom: Radius.elliptical(300, 40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 4.h, 16.w, 28.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.arrowLeft,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: donor.image.isEmpty
                                  ? Center(
                                      child: Text(
                                        donor.firstName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 26.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade600,
                                        ),
                                      ),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: donor.image,
                                      width: 64.w,
                                      height: 64.h,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => Icon(
                                        PhosphorIcons.warningCircle,
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${donor.firstName} ${donor.lastName}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Wrap(
                                    spacing: 6.w,
                                    runSpacing: 6.h,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                        ),
                                        child: Text(
                                          donor.bloodGroup,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                      if (donor.isEmergencyDonor)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 3.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                PhosphorIcons.siren,
                                                color: Colors.white,
                                                size: 12.w,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Emergency Donor',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (isVerified)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 3.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified,
                                                color: Colors.blue.shade100,
                                                size: 13.w,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (donor.locationAddress != null &&
                                      donor.locationAddress!.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 6.h),
                                      child: Text(
                                        donor.locationAddress!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.availability != null) ...[
                  _AvailabilityCard(availability: widget.availability!),
                  SizedBox(height: 12.h),
                ],
                _ContactCard(donor: donor, onCall: _launchUrl),
                SizedBox(height: 12.h),
                _LastDonationCard(uid: donor.uid),
                if (donor.latitude != null && donor.longitude != null) ...[
                  SizedBox(height: 12.h),
                  _LocationMapCard(
                    donor: donor,
                    finderLatitude: widget.finderLatitude,
                    finderLongitude: widget.finderLongitude,
                    mapController: _mapController,
                    onMapReady: _fitMapToMarkers,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final UserModel donor;
  final void Function(String url) onCall;

  const _ContactCard({required this.donor, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  PhosphorIcons.phoneCall,
                  size: 15,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Contact',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (donor.mobileNumber.isNotEmpty)
            InkWell(
              onTap: () => onCall('tel:${donor.mobileNumber}'),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
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
                      child: Icon(
                        PhosphorIcons.phoneCall,
                        size: 18,
                        color: Colors.red.shade600,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            donor.mobileNumber,
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
              ),
            ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: StartChatButton(otherUserId: donor.uid),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final String availability;

  const _AvailabilityCard({required this.availability});

  static const _options = {
    'available': ('Available to Donate', Icons.check_circle, Colors.green),
    'out_of_city': ('Out of City', Icons.flight_takeoff, Colors.orange),
    'unavailable': ("Can't Donate Right Now", Icons.block, Colors.red),
  };

  @override
  Widget build(BuildContext context) {
    final option = _options[availability] ?? _options['available']!;
    final (label, icon, color) = option;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastDonationCard extends ConsumerWidget {
  final String uid;

  const _LastDonationCard({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsStream = ref
        .read(userRepositoryProvider)
        .donationsStream(uid);

    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(16.w),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: donationsStream,
        builder: (context, snapshot) {
          String value = 'No donation records yet';
          if (snapshot.connectionState == ConnectionState.waiting) {
            value = 'Loading...';
          } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final data = snapshot.data!.docs.first.data();
            final timestamp = data['donationDate'] as Timestamp?;
            if (timestamp != null) {
              value = DateFormat('dd MMM yyyy').format(timestamp.toDate());
            }
          }

          return Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  PhosphorIcons.drop,
                  size: 18,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Donation',
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
            ],
          );
        },
      ),
    );
  }
}

class _LocationMapCard extends StatelessWidget {
  final UserModel donor;
  final double? finderLatitude;
  final double? finderLongitude;
  final MapController mapController;
  final VoidCallback onMapReady;

  const _LocationMapCard({
    required this.donor,
    required this.finderLatitude,
    required this.finderLongitude,
    required this.mapController,
    required this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    final donorPoint = LatLng(donor.latitude!, donor.longitude!);
    final hasFinder = finderLatitude != null && finderLongitude != null;
    final finderPoint = hasFinder
        ? LatLng(finderLatitude!, finderLongitude!)
        : null;

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 8.h),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    PhosphorIcons.mapPin,
                    size: 15,
                    color: Colors.red.shade600,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220.h,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: donorPoint,
                initialZoom: 13,
                onMapReady: onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sofolitltd.bloodfinder',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: donorPoint,
                      width: 44.w,
                      height: 52.h,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44.w,
                      ),
                    ),
                    if (finderPoint != null)
                      Marker(
                        point: finderPoint,
                        width: 44.w,
                        height: 52.h,
                        child: Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40.w,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
            child: Row(
              children: [
                _MapLegendDot(color: Colors.red, label: 'Donor'),
                SizedBox(width: 16.w),
                if (hasFinder) _MapLegendDot(color: Colors.blue, label: 'You'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMapsDirections(
                  origin: finderPoint,
                  destination: donorPoint,
                ),
                icon: Icon(PhosphorIcons.navigationArrow, size: 18.w),
                label: Text(
                  hasFinder
                      ? 'Navigate to Donor (Google Maps)'
                      : 'View Donor on Google Maps',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMapsDirections({
    required LatLng? origin,
    required LatLng destination,
  }) async {
    final destParam = '${destination.latitude},${destination.longitude}';
    final uri = origin != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=$destParam'
            '&travelmode=driving',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$destParam',
          );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MapLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
