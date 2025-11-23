import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  const LocationPickerResult({required this.latLng, required this.address});

  final LatLng latLng;
  final String address;
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final LatLng _fallback = LatLng(14.5995, 120.9842); // Manila
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  String? _address;
  bool _isLoading = true;
  bool _isGeocoding = false;
  bool _isRecentering = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      await _ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLatLng = latLng;
        _isLoading = false;
      });
      _animateTo(latLng);
      await _reverseGeocode(latLng);
    } catch (_) {
      setState(() {
        _selectedLatLng = _fallback;
        _isLoading = false;
      });
      _animateTo(_fallback);
      await _reverseGeocode(_fallback);
    }
  }

  Future<void> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    setState(() => _isRecentering = true);
    try {
      await _ensureLocationPermission();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLatLng = latLng;
      });
      _animateTo(latLng);
      await _reverseGeocode(latLng);
    } catch (_) {
      // ignore errors; keep previous pin if lookup fails
    } finally {
      if (mounted) {
        setState(() => _isRecentering = false);
      }
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final buffer = StringBuffer();
        if ((place.street ?? '').isNotEmpty) buffer.write(place.street);
        if ((place.subLocality ?? '').isNotEmpty) {
          buffer.write(', ${place.subLocality}');
        }
        if ((place.locality ?? '').isNotEmpty) {
          buffer.write(', ${place.locality}');
        }
        if ((place.administrativeArea ?? '').isNotEmpty) {
          buffer.write(', ${place.administrativeArea}');
        }
        setState(() {
          _address = buffer.isEmpty
              ? '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}'
              : buffer.toString();
        });
      }
    } catch (_) {
      setState(() {
        _address = 'Pinned location on map (describe details below)';
      });
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  void _animateTo(LatLng target) {
    _mapController.move(target, 17);
  }

  void _onMapTap(LatLng latLng) {
    setState(() => _selectedLatLng = latLng);
    _reverseGeocode(latLng);
  }

  void _confirmSelection() {
    if (_selectedLatLng == null) return;
    final address =
        _address ??
        '${_selectedLatLng!.latitude.toStringAsFixed(4)}, '
            '${_selectedLatLng!.longitude.toStringAsFixed(4)}';
    Navigator.of(
      context,
    ).pop(LocationPickerResult(latLng: _selectedLatLng!, address: address));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng ?? _fallback,
                    initialZoom: 17,
                    onTap: (_, latLng) => _onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ph.bayankonek.app',
                      tileProvider: NetworkTileProvider(
                        // Custom User-Agent lets OpenStreetMap contact us if needed
                        headers: {
                          'User-Agent':
                              'BayanKonek/1.0 (support@bayankonek.app)',
                        },
                      ),
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              size: 38,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 210,
                  right: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter-location',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F6FE3),
                    onPressed: _isRecentering ? null : _centerOnCurrentLocation,
                    child: _isRecentering
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _address ?? 'Tap on the map to choose a spot.',
                              style: const TextStyle(color: Color(0xFF4F596A)),
                            ),
                            if (_isGeocoding)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: LinearProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedLatLng == null
                              ? null
                              : _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F6FE3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Use This Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
