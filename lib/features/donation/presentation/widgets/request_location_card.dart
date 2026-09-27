import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the poster's request location on a map alongside the current
/// user's location (when available), with a "Navigate (Google Maps)" button.
class RequestLocationCard extends StatefulWidget {
  final double posterLatitude;
  final double posterLongitude;
  final double? finderLatitude;
  final double? finderLongitude;

  const RequestLocationCard({
    super.key,
    required this.posterLatitude,
    required this.posterLongitude,
    this.finderLatitude,
    this.finderLongitude,
  });

  @override
  State<RequestLocationCard> createState() => _RequestLocationCardState();
}

class _RequestLocationCardState extends State<RequestLocationCard> {
  final MapController _mapController = MapController();

  bool get _hasFinder =>
      widget.finderLatitude != null && widget.finderLongitude != null;

  void _fitMapToMarkers() {
    if (!_hasFinder) return;
    final posterPoint = LatLng(widget.posterLatitude, widget.posterLongitude);
    final finderPoint = LatLng(widget.finderLatitude!, widget.finderLongitude!);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(posterPoint, finderPoint),
        padding: EdgeInsets.all(48.w),
      ),
    );
  }

  void _openGoogleMapsDirections() async {
    final destParam = '${widget.posterLatitude},${widget.posterLongitude}';
    final uri = _hasFinder
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${widget.finderLatitude},${widget.finderLongitude}'
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

  @override
  Widget build(BuildContext context) {
    final posterPoint = LatLng(widget.posterLatitude, widget.posterLongitude);
    final finderPoint = _hasFinder
        ? LatLng(widget.finderLatitude!, widget.finderLongitude!)
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
          SizedBox(
            height: 220.h,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: posterPoint,
                initialZoom: 13,
                onMapReady: _fitMapToMarkers,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sofolitltd.bloodfinder',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: posterPoint,
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
                _LegendDot(color: Colors.red, label: 'Poster'),
                SizedBox(width: 16.w),
                if (_hasFinder) _LegendDot(color: Colors.blue, label: 'You'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMapsDirections,
                icon: Icon(PhosphorIcons.navigationArrow, size: 18.w),
                label: Text(
                  _hasFinder
                      ? 'Navigate to Poster (Google Maps)'
                      : 'View Poster on Google Maps',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

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
