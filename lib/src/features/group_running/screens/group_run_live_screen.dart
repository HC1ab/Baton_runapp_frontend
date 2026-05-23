import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../social/models/run_card_data.dart';
import '../models/participant_location.dart';
import '../providers/run_location_provider.dart';

/// Group run live map — STOMP location stream + Google Maps markers.
class GroupRunLiveScreen extends ConsumerStatefulWidget {
  const GroupRunLiveScreen({super.key, required this.card});

  final RunCardData card;

  @override
  ConsumerState<GroupRunLiveScreen> createState() => _GroupRunLiveScreenState();
}

class _GroupRunLiveScreenState extends ConsumerState<GroupRunLiveScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription<Position>? _gpsSub;
  final Map<int, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final groupId = widget.card.groupId;
    if (groupId == null) return;

    await ref.read(runLocationProvider.notifier).joinRoom(groupId);
    _startLocalGpsTracking();
  }

  void _startLocalGpsTracking() {
    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      if (!mounted) return;
      ref.read(runLocationProvider.notifier).updateMyLocation(
            pos.latitude,
            pos.longitude,
          );
      unawaited(_moveCameraIfNeeded(pos.latitude, pos.longitude));
    });
  }

  Future<void> _moveCameraIfNeeded(double lat, double lng) async {
    final ctrl = _mapCtrl;
    if (ctrl == null || !mounted) return;
    await ctrl.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 16),
      ),
    );
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _mapCtrl?.dispose();
    unawaited(ref.read(runLocationProvider.notifier).leaveRoom());
    super.dispose();
  }

  void _syncMarkers(RunLocationState locState) {
    if (!mounted) return;

    final all = <int, ParticipantLocation>{
      ...locState.participants,
      if (locState.myLocation != null) locState.myMemberId!: locState.myLocation!,
    };

    final newMarkers = <int, Marker>{};
    for (final entry in all.entries) {
      final isMe = entry.key == locState.myMemberId;
      final pos = LatLng(entry.value.latitude, entry.value.longitude);
      final label = isMe ? '나' : (entry.value.nickname ?? '러너 ${entry.key}');

      newMarkers[entry.key] = Marker(
        markerId: MarkerId('participant_${entry.key}'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isMe
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueCyan,
        ),
        infoWindow: InfoWindow(title: label),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(runLocationProvider);
    final card = widget.card;
    final target = LatLng(card.latitude, card.longitude);

    ref.listen<RunLocationState>(runLocationProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncMarkers(next);
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        title: Text(
          card.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1F1F),
          ),
        ),
        actions: [
          _ConnectionBadge(state: locState.connectionState),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers.values.toSet(),
              onMapCreated: (ctrl) {
                _mapCtrl = ctrl;
                _syncMarkers(locState);
              },
            ),
          ),
          if (locState.errorMessage != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFEBEE),
              padding: const EdgeInsets.all(12),
              child: Text(
                locState.errorMessage!,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '참가자 ${locState.participants.length + (locState.myLocation != null ? 1 : 0)}명 표시 중',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const Spacer(),
                  if (locState.isConnected)
                    const Icon(Icons.circle, size: 10, color: Color(0xFF4CAF50)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});

  final RunLocationConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      RunLocationConnectionState.connected => ('연결됨', const Color(0xFF4CAF50)),
      RunLocationConnectionState.connecting => ('연결 중…', const Color(0xFFFF9800)),
      RunLocationConnectionState.error => ('오류', const Color(0xFFE53935)),
      RunLocationConnectionState.idle => ('대기', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
