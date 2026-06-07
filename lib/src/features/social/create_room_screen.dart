import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/error_messages.dart';
import '../../core/network/api_client.dart';
import 'location_picker_screen.dart';
import 'models/run_card_data.dart';
import 'social_providers.dart';
import 'widgets/custom_input_field.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  static const Color _background = AppColors.scaffoldGrey;
  static const Color _submitOrange = AppColors.socialAccent;
  static const Color _accentBrown = AppColors.inputAccent;

  static final List<String> _distanceOptions = [
    ...List<String>.generate(42, (i) => '${i + 1}km'),
    '42.195km',
  ];

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _membersController = TextEditingController();
  final _distanceController = TextEditingController();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int _memberCount = 2;
  int _distanceIndex = 4;
  LatLng? _selectedLatLng;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final end = now.add(const Duration(minutes: 30));
    _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    _syncTimeControllers();
    _syncMemberDistanceControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _placeNameController.dispose();
    _addressController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _membersController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _syncTimeControllers() {
    _startTimeController.text = _formatTimeKo(_startTime);
    _endTimeController.text = _formatTimeKo(_endTime);
  }

  void _syncMemberDistanceControllers() {
    _membersController.text = '$_memberCount명';
    _distanceController.text = _distanceOptions[_distanceIndex];
  }

  String _formatTimeKo(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final isPm = h >= 12;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${isPm ? '오후' : '오전'} $h12:$m';
  }

  /// 지도에서 좌표를 고른 뒤 역지오코딩으로 주소를 채웁니다.
  Future<void> _openMapPicker() async {
    // 이전 선택 좌표 없으면 현재 GPS 위치를 초기 좌표로 사용
    LatLng? startLatLng = _selectedLatLng;
    if (startLatLng == null) {
      try {
        Position? pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        startLatLng = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        // 권한 없거나 실패 → LocationPickerScreen 자체 fallback 사용
      }
    }

    if (!mounted) return;
    final selected = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => LocationPickerScreen(initialLatLng: startLatLng),
      ),
    );
    if (!mounted || selected == null) return;
    _selectedLatLng = selected;

    try {
      await setLocaleIdentifier('ko_KR');
      final placemarks = await placemarkFromCoordinates(
        selected.latitude,
        selected.longitude,
      );

      if (placemarks.isEmpty) {
        setState(() {
          _addressController.text = '주소를 찾을 수 없습니다';
        });
        return;
      }

      final line = _koreanAddressLine(placemarks.first);
      setState(() {
        _addressController.text =
            line.isEmpty ? '주소를 찾을 수 없습니다' : line;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressController.text = '주소를 찾을 수 없습니다';
        });
      }
    }
  }

  /// [Placemark]에서 최대한 상세한 도로명 주소 한 줄을 만듭니다.
  String _koreanAddressLine(Placemark p) {
    final parts = <String>[];
    void add(String? s) {
      final t = s?.trim();
      if (t != null && t.isNotEmpty && !parts.contains(t)) {
        parts.add(t);
      }
    }

    add(p.administrativeArea);
    add(p.subAdministrativeArea);
    add(p.locality);
    add(p.subLocality);
    add(p.thoroughfare);
    add(p.subThoroughfare);
    if (parts.length < 3) {
      add(p.street);
      add(p.name);
    }
    if (parts.isEmpty) {
      add(p.street);
      add(p.name);
    }
    return parts.join(' ');
  }

  int _distanceValueFromOption(String option) {
    if (option == '42.195km') return 42;
    return int.tryParse(option.replaceAll('km', '')) ?? 5;
  }

  DateTime _combineDateAndTime(DateTime baseDate, TimeOfDay time) {
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );
  }

  String _formatFeedTime(DateTime dateTime) {
    final isPm = dateTime.hour >= 12;
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '오늘 ${isPm ? '오후' : '오전'} $hour12:$minute';
  }

  Future<void> _submitRoom() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final placeName = _placeNameController.text.trim();
    final address = _addressController.text.trim();

    if (title.isEmpty || content.isEmpty || placeName.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목, 내용, 장소명, 주소를 모두 입력해 주세요.')),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = _combineDateAndTime(now, _startTime);
    var endDateTime = _combineDateAndTime(now, _endTime);
    if (!endDateTime.isAfter(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final distanceText = _distanceOptions[_distanceIndex];
    final distanceValue = _distanceValueFromOption(distanceText);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final groupId = await ref.read(groupApiProvider).create(
            title: title,
            content: content,
            maxParticipants: _memberCount,
            startTimeIsoLocal: DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startDateTime),
            endTimeIsoLocal: DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(endDateTime),
            distanceKm: distanceValue,
            location: placeName,
            address: address,
            latitude: _selectedLatLng?.latitude,
            longitude: _selectedLatLng?.longitude,
          );
      if (!mounted) return;
      Navigator.of(context).pop<RunCardData>(
        RunCardData(
          groupId: groupId,
          isHost: true,
          isParticipating: true,
          title: title,
          time: _formatFeedTime(startDateTime),
          location: placeName,
          latitude: _selectedLatLng?.latitude,
          longitude: _selectedLatLng?.longitude,
          currentMembers: 1,
          maxMembers: _memberCount,
          participantImageUrls: const [''],
          endTimeLabel: _formatTimeKo(_endTime),
          targetDistance: distanceText,
          placeName: placeName,
          detailAddress: address,
          body: content,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiErrorMessage(e))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.unknownError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _startTime = picked;
      _startTimeController.text = _formatTimeKo(picked);
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _endTime = picked;
      _endTimeController.text = _formatTimeKo(picked);
    });
  }

  void _showMemberPicker() {
    var temp = _memberCount;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 280.h,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  '모집 인원',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: temp - 1,
                    ),
                    itemExtent: 40.h,
                    onSelectedItemChanged: (i) {
                      temp = i + 1;
                    },
                    children: List.generate(
                      5,
                      (i) => Center(
                        child: Text(
                          '${i + 1}명',
                          style: TextStyle(fontSize: 20.sp),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _memberCount = temp;
                          _membersController.text = '$_memberCount명';
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _submitOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDistancePicker() {
    var temp = _distanceIndex;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 280.h,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  '목표 거리',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: temp,
                    ),
                    itemExtent: 40.h,
                    onSelectedItemChanged: (i) => temp = i,
                    children: _distanceOptions
                        .map(
                          (e) => Center(
                            child: Text(
                              e,
                              style: TextStyle(fontSize: 20.sp),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _distanceIndex = temp;
                          _distanceController.text =
                              _distanceOptions[_distanceIndex];
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _submitOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '새로운 러닝 모집',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 8.h, AppSpacing.screenHorizontal, 24.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomInputField(
                      label: '제목',
                      controller: _titleController,
                      hintText: '러닝 모집 제목을 입력하세요',
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: '모집 내용',
                      controller: _contentController,
                      hintText: '모집 내용을 입력하세요',
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: '장소명',
                      controller: _placeNameController,
                      hintText: '예: 반포 한강공원',
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: '주소',
                      controller: _addressController,
                      hintText: '지도에서 선택',
                      readOnly: true,
                      onTap: () {
                        _openMapPicker();
                      },
                      suffixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: _accentBrown,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomInputField(
                            label: '시작 시간',
                            controller: _startTimeController,
                            readOnly: true,
                            onTap: _pickStartTime,
                            suffixIcon: const Icon(
                              Icons.access_time_filled_rounded,
                              color: _accentBrown,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: CustomInputField(
                            label: '종료 시간',
                            controller: _endTimeController,
                            readOnly: true,
                            onTap: _pickEndTime,
                            suffixIcon: const Icon(
                              Icons.schedule_rounded,
                              color: _accentBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomInputField(
                            label: '모집 인원',
                            controller: _membersController,
                            readOnly: true,
                            onTap: _showMemberPicker,
                            suffixIcon: const Icon(
                              Icons.groups_rounded,
                              color: _accentBrown,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: CustomInputField(
                            label: '목표 거리',
                            controller: _distanceController,
                            readOnly: true,
                            onTap: _showDistancePicker,
                            suffixIcon: const Icon(
                              Icons.straighten_rounded,
                              color: _accentBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 8.h, AppSpacing.screenHorizontal, 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: FilledButton(
                  onPressed: _submitRoom,
                  style: FilledButton.styleFrom(
                    backgroundColor: _submitOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    textStyle: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.white,
                          ),
                        )
                      : const Text('글쓰기 완료'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
