import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 지도에서 한 지점을 탭해 좌표를 선택하는 전체 화면.
/// 선택 완료 시 `Navigator.pop(context, LatLng)`로 결과를 반환합니다.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLatLng});

  final LatLng? initialLatLng;

  static const Color _submitOrange = Color(0xFFF7673B);

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(35.1631, 129.0536),
    zoom: 15,
  );

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  Marker? _marker;
  LatLng? _selectedLatLng;

  Future<void> _onMapTapped(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _marker = Marker(
        markerId: const MarkerId('location_pick_marker'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
  }

  void _confirm() {
    final selected = _selectedLatLng;
    if (selected == null) return;
    Navigator.of(context).pop<LatLng>(selected);
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
          GoogleMap(
            initialCameraPosition: widget.initialLatLng != null
                ? CameraPosition(target: widget.initialLatLng!, zoom: 16)
                : LocationPickerScreen._initialCamera,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            markers: _marker != null ? {_marker!} : {},
            onMapCreated: (ctrl) {
              // 초기 위치가 있으면 마커 표시
              final initial = widget.initialLatLng;
              if (initial != null) _onMapTapped(initial);
            },
            onTap: _onMapTapped,
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
