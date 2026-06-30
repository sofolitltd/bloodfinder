import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen interactive map picker with search bar, zoom controls, and GPS.
class MapLocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  static Future<MapPickResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
  }) {
    return Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapLocationPickerPage(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
        ),
      ),
    );
  }

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  static const _defaultLocation = LatLng(23.8103, 90.4125);
  static const _defaultZoom = 13.0;

  late final MapController _mapController;
  LatLng _pickedPoint = _defaultLocation;
  String _displayAddress = '';
  bool _isGpsLoading = false;
  bool _isReverseGeocoding = false;
  Timer? _debounce;

  // Search bar state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _pickedPoint = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _reverseGeocode(_pickedPoint);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── GPS ─────────────────────────────────────────────────────────────────────

  Future<void> _useGpsLocation() async {
    setState(() => _isGpsLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Permission permanently denied. Enable it in Settings.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            LocationSettings(accuracy: LocationAccuracy.high),
      );

      final point = LatLng(pos.latitude, pos.longitude);
      _mapController.move(point, 15);
      setState(() => _pickedPoint = point);
      await _reverseGeocode(point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  // ── Zoom ─────────────────────────────────────────────────────────────────────

  void _zoomIn() =>
      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);

  void _zoomOut() =>
      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);

  // ── Location search (forward geocode) ────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      _forwardGeocode(query.trim());
    });
  }

  Future<void> _forwardGeocode(String query) async {
    setState(() => _isSearching = true);
    try {
      final client = HttpClient()..userAgent = 'BloodFinderApp/1.0';
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&accept-language=en';
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        setState(() {
          _searchResults = list
              .map((e) => _SearchResult(
                    displayName: e['display_name'] as String,
                    lat: double.parse(e['lat'] as String),
                    lon: double.parse(e['lon'] as String),
                  ))
              .toList();
          _showResults = _searchResults.isNotEmpty;
        });
      }
      client.close();
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.lat, result.lon);
    _mapController.move(point, 14);
    setState(() {
      _pickedPoint = point;
      _displayAddress = result.displayName;
      _searchController.text = result.displayName;
      _searchResults = [];
      _showResults = false;
    });
    _searchFocus.unfocus();
  }

  // ── Reverse geocode (tap) ─────────────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isReverseGeocoding = true;
      _displayAddress = 'Finding address...';
    });
    try {
      final client = HttpClient()..userAgent = 'BloodFinderApp/1.0';
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json&accept-language=en';
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        setState(() => _displayAddress = json['display_name'] as String? ?? '');
      } else {
        setState(() => _displayAddress =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}');
      }
      client.close();
    } catch (_) {
      setState(() => _displayAddress =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _searchFocus.unfocus();
    setState(() {
      _pickedPoint = point;
      _showResults = false;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(point);
    });
  }

  void _confirmLocation() {
    if (_displayAddress.isEmpty || _displayAddress == 'Finding address...') {
      _displayAddress =
          '${_pickedPoint.latitude.toStringAsFixed(5)}, ${_pickedPoint.longitude.toStringAsFixed(5)}';
    }
    Navigator.pop(
      context,
      MapPickResult(
        latitude: _pickedPoint.latitude,
        longitude: _pickedPoint.longitude,
        displayAddress: _displayAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        centerTitle: true,
        actions: [
          _isGpsLoading
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : IconButton(
                  tooltip: 'Use my GPS location',
                  icon: const Icon(Icons.my_location),
                  onPressed: _useGpsLocation,
                ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedPoint,
              initialZoom: _defaultZoom,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sofolitltd.bloodfinder',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedPoint,
                    width: 48.w,
                    height: 56.h,
                    child: Icon(Icons.location_pin, color: Colors.red, size: 48.w),
                  ),
                ],
              ),
            ],
          ),

          // ── Search bar (top) ─────────────────────────────────────────────────
          Positioned(
            top: 12.h,
            left: 12.w,
            right: 12.w,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    onSubmitted: (q) {
                      if (q.trim().isNotEmpty) _forwardGeocode(q.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _isSearching
                          ? Padding(
                              padding: EdgeInsets.all(12.r),
                              child: SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18.w),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _showResults = false;
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),

                if (_showResults && _searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1.h, indent: 48),
                      itemBuilder: (_, i) {
                        final r = _searchResults[i];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on_outlined,
                                color: Colors.redAccent, size: 20.w),
                            title: Text(
                              r.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            onTap: () => _selectSearchResult(r),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Zoom controls (right side) ────────────────────────────────────────
          Positioned(
            right: 12.w,
            bottom: 180.h,
            child: Column(
              children: [
                _ZoomButton(icon: Icons.add, onTap: _zoomIn),
                SizedBox(height: 8.h),
                _ZoomButton(icon: Icons.remove, onTap: _zoomOut),
              ],
            ),
          ),

          // ── Bottom sheet: address + confirm ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 20.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _isReverseGeocoding
                            ? const Text('Finding address...',
                                style: TextStyle(color: Colors.grey))
                            : Text(
                                _displayAddress.isNotEmpty
                                    ? _displayAddress
                                    : 'Tap on the map to select a location',
                                style: TextStyle(fontSize: 13.sp, height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _isReverseGeocoding ? null : _confirmLocation,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8.r),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 40.w,
          height: 40.h,
          child: Icon(icon, size: 22.w, color: Colors.black87),
        ),
      ),
    );
  }
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lon;

  const _SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}

/// Result returned when the user confirms a location on the map.
class MapPickResult {
  final double latitude;
  final double longitude;
  final String displayAddress;

  const MapPickResult({
    required this.latitude,
    required this.longitude,
    required this.displayAddress,
  });
}
