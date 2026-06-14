import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../theme/app_theme.dart';

class MapsScreen extends StatefulWidget {
  final LGController lgController;

  const MapsScreen({super.key, required this.lgController});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final KmlBuilderService _kmlBuilder = KmlBuilderService();
  GoogleMapController? _mapController;
  Timer? _syncTimer;
  bool _isSyncing = true;
  bool _isOrbiting = false;
  CameraPosition _currentPosition = const CameraPosition(
    target: LatLng(22.0, 82.0),
    zoom: 5,
    tilt: 0,
    bearing: 0,
  );

  @override
  void dispose() {
    _syncTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position;

    if (!_isSyncing) return;

    // Throttle — cancel previous timer and set new one
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 300), () {
      _syncToLG(position);
    });
  }

  Future<void> _syncToLG(CameraPosition position) async {
    if (!widget.lgController.isConnected) return;

    // Convert Google Maps zoom to KML range
    // Zoom 1 ≈ 20000km, Zoom 20 ≈ 50m
    final range = 591657550.5 / (1 << position.zoom.toInt());

    try {
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(
          lat: position.target.latitude,
          lng: position.target.longitude,
          range: range.clamp(100, 20000000),
          tilt: position.tilt,
          heading: position.bearing,
        ),
      );
    } catch (e) {
      // Silently fail — don't spam errors during dragging
    }
  }

  Future<void> _orbitHere() async {
    if (_isOrbiting) return;
    setState(() => _isOrbiting = true);

    final lat = _currentPosition.target.latitude;
    final lng = _currentPosition.target.longitude;
    final range = 591657550.5 / (1 << _currentPosition.zoom.toInt());

    final sequence = _kmlBuilder.buildOrbitSequence(
      lat: lat,
      lng: lng,
      range: range.clamp(5000, 2000000),
      tilt: 60,
      steps: 24,
    );

    for (final lookAt in sequence) {
      if (!_isOrbiting) break;
      if (!widget.lgController.isConnected) break;
      await widget.lgController.safeQuery(lookAt);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() => _isOrbiting = false);
  }

  Future<void> _flyToIndia() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(22.0, 82.0),
          zoom: 5,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildMap()),
              _buildInfoBar(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _syncTimer?.cancel();
              _isOrbiting = false;
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Synced Navigation',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _isSyncing = !_isSyncing);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isSyncing
                    ? const Color(0xFF66BB6A).withOpacity(0.15)
                    : Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isSyncing
                      ? const Color(0xFF66BB6A).withOpacity(0.3)
                      : Colors.redAccent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSyncing ? Icons.sync : Icons.sync_disabled,
                    color: _isSyncing
                        ? const Color(0xFF66BB6A)
                        : Colors.redAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSyncing ? 'Synced' : 'Paused',
                    style: TextStyle(
                      color: _isSyncing
                          ? const Color(0xFF66BB6A)
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: GoogleMap(
        initialCameraPosition: _currentPosition,
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        mapType: MapType.hybrid,
        myLocationEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        tiltGesturesEnabled: true,
        rotateGesturesEnabled: true,
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.explore, color: AppTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(
            'Lat: ${_currentPosition.target.latitude.toStringAsFixed(3)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'Lng: ${_currentPosition.target.longitude.toStringAsFixed(3)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'Zoom: ${_currentPosition.zoom.toStringAsFixed(1)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const Spacer(),
          if (_isOrbiting)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF42A5F5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isOrbiting ? null : _orbitHere,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rotate_right,
                      color: _isOrbiting
                          ? Colors.grey
                          : const Color(0xFF42A5F5),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOrbiting ? 'Orbiting...' : 'Orbit here',
                      style: TextStyle(
                        color: _isOrbiting
                            ? Colors.grey
                            : const Color(0xFF42A5F5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _flyToIndia,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flight, color: AppTheme.textSecondary, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Fly to India',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
