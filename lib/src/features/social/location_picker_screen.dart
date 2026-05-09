import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

/// 지도에서 한 지점을 탭해 좌표를 선택하는 전체 화면.
/// 선택 완료 시 `Navigator.pop(context, NLatLng)`로 결과를 반환합니다.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLatLng});

  final NLatLng? initialLatLng;

  static const Color _submitOrange = Color(0xFFF7673B);

  static final NCameraPosition _initialCamera = NCameraPosition(
    target: NLatLng(35.1631, 129.0536),
    zoom: 15,
  );

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  NaverMapController? _map;
  NMarker? _marker;
  NLatLng? _selectedLatLng;
  NLatLng? _pendingTapLatLng;

  Future<void> _onMapTapped(NPoint _, NLatLng latLng) async {
    final map = _map;
    if (map == null) {
      setState(() {
        _pendingTapLatLng = latLng;
        _selectedLatLng = latLng;
      });
      return;
    }

    if (_marker == null) {
      final next = NMarker(
        id: 'location_pick_marker',
        position: latLng,
        iconTintColor: Colors.red,
      );
      await map.addOverlay(next);
      _marker = next;
    } else {
      _marker!.setPosition(latLng);
    }

    setState(() {
      _selectedLatLng = latLng;
    });
  }

  void _confirm() {
    final selected = _selectedLatLng;
    if (selected == null) return;
    Navigator.of(context).pop<NLatLng>(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: LocationPickerScreen._initialCamera,
              locale: const Locale('ko'),
            ),
            onMapReady: (controller) {
              _map = controller;
              final initial = widget.initialLatLng;
              if (initial != null) {
                controller.updateCamera(
                  NCameraUpdate.fromCameraPosition(
                    NCameraPosition(target: initial, zoom: 16),
                  ),
                );
                _onMapTapped(NPoint(0,0), initial);
                return;
              }

              final pending = _pendingTapLatLng;
              if (pending != null) {
                _pendingTapLatLng = null;
                _onMapTapped(NPoint(0,0), pending);
              }
            },
            onMapTapped: _onMapTapped,
          ),
          if (_selectedLatLng != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: LocationPickerScreen._submitOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('이 위치로 설정하기'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
