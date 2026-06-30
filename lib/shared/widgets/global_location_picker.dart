import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:country_state_city_selector/country_state_city_selector.dart';

class GlobalLocationPicker extends StatefulWidget {
  const GlobalLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.initialLatitude,
    this.initialLongitude,
  });

  final Function(
    String country,
    String state,
    String city,
    double latitude,
    double longitude,
  ) onLocationSelected;

  final String? initialCountry;
  final String? initialState;
  final String? initialCity;
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<GlobalLocationPicker> createState() => _GlobalLocationPickerState();
}

class _GlobalLocationPickerState extends State<GlobalLocationPicker> {
  String? _country;
  String? _state;
  String? _city;
  double? _latitude;
  double? _longitude;
  bool _isLoadingGps = false;
  bool _isGeocoding = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry;
    _state = widget.initialState;
    _city = widget.initialCity;
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  // Fetch coordinates for manual selection
  Future<void> _fetchCoordinatesForManualSelection(
      String country, String state, String city) async {
    if (country.isEmpty) return;

    setState(() {
      _isGeocoding = true;
      _statusMessage = 'Resolving location coordinates...';
    });

    final queryParts = <String>[];
    if (city.isNotEmpty) queryParts.add(city);
    if (state.isNotEmpty) queryParts.add(state);
    queryParts.add(country);

    final query = Uri.encodeComponent(queryParts.join(', '));
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
    final client = HttpClient();
    client.userAgent = 'BloodFinderApp/1.0';

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final List results = json.decode(jsonString);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'].toString());
          final lon = double.tryParse(results[0]['lon'].toString());
          if (lat != null && lon != null) {
            setState(() {
              _latitude = lat;
              _longitude = lon;
              _statusMessage = null;
            });
            widget.onLocationSelected(country, state, city, lat, lon);
            return;
          }
        }
      }
      setState(() {
        _statusMessage = 'Could not resolve exact coordinates. Defaulting to general region.';
      });
      // Fallback defaults close to center of country if resolving fails
      widget.onLocationSelected(country, state, city, 0.0, 0.0);
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection error. Coordinate lookup failed.';
      });
      widget.onLocationSelected(country, state, city, 0.0, 0.0);
    } finally {
      client.close();
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  // Reverse geocoding for GPS location
  Future<void> _fetchAddressFromGps(double lat, double lon) async {
    setState(() {
      _isGeocoding = true;
      _statusMessage = 'Resolving physical address...';
    });

    final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
    final client = HttpClient();
    client.userAgent = 'BloodFinderApp/1.0';

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> result = json.decode(jsonString);
        final address = result['address'] as Map<String, dynamic>?;

        if (address != null) {
          final country = address['country']?.toString() ?? '';
          final state = address['state']?.toString() ?? address['region']?.toString() ?? address['county']?.toString() ?? '';
          final city = address['city']?.toString() ?? address['town']?.toString() ?? address['suburb']?.toString() ?? address['village']?.toString() ?? '';

          setState(() {
            _country = country;
            _state = state;
            _city = city;
            _latitude = lat;
            _longitude = lon;
            _statusMessage = null;
          });
          widget.onLocationSelected(country, state, city, lat, lon);
          return;
        }
      }
      setState(() {
        _statusMessage = 'Could not read physical address details.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load address details.';
      });
    } finally {
      client.close();
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  Future<void> _getLocationFromGps() async {
    setState(() {
      _isLoadingGps = true;
      _statusMessage = 'Accessing device GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled on your device.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions were denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in system settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _fetchAddressFromGps(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _statusMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingGps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedLocation = _country != null && _country!.isNotEmpty;
    final displayLocation = hasSelectedLocation
        ? [if (_city?.isNotEmpty ?? false) _city, if (_state?.isNotEmpty ?? false) _state, _country]
            .join(', ')
        : 'No location selected';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.redAccent),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  displayLocation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            hasSelectedLocation ? FontWeight.w600 : FontWeight.normal,
                        color: hasSelectedLocation
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                ),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 4.0),
            Text(
              'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: _isLoadingGps || _isGeocoding ? null : _getLocationFromGps,
              icon: _isLoadingGps
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isLoadingGps ? 'Locating...' : 'Use Current Location',
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  'OR SELECT MANUALLY',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16.0),
          CountryStateCitySelector(
            countryHintText: 'Select Country',
            stateHintText: 'Select State/Division',
            cityHintText: 'Select City/District',
            onSelectionChanged: (country, state, city) {
              setState(() {
                _country = country;
                _state = state;
                _city = city;
              });
              _fetchCoordinatesForManualSelection(country, state, city);
            },
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12.0),
            Text(
              _statusMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isGeocoding ? Colors.blueAccent : Colors.orangeAccent,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
