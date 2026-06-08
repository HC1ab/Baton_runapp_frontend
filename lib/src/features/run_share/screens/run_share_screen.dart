import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/run_share_data.dart';
import '../providers/run_share_provider.dart';
import '../widgets/share_canvas_widget.dart';
import '../widgets/share_customize_sheet.dart';

final _logger = Logger();

class RunShareScreen extends ConsumerStatefulWidget {
  const RunShareScreen({super.key, required this.data});

  final RunShareData data;

  @override
  ConsumerState<RunShareScreen> createState() => _RunShareScreenState();
}

class _RunShareScreenState extends ConsumerState<RunShareScreen> {
  final _repaintKey = GlobalKey();
  final _picker = ImagePicker();

  File? _backgroundImage;
  bool _isSaving = false;

  // ── 배경 이미지 선택 ────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (xFile == null) return;
      if (!mounted) return;
      setState(() => _backgroundImage = File(xFile.path));
    } catch (e) {
      _logger.e('Image pick failed', error: e);
      if (!mounted) return;
      _showSnackBar('이미지를 불러오지 못했습니다.');
    }
  }

  // ── 이미지 저장 ────────────────────────────────────────────────────────────

  Future<void> _saveImage() async {
    if (_isSaving) return;
    // 선택 핸들/테두리가 이미지에 포함되지 않도록 선택 해제 후 프레임 대기
    ref.read(runShareProvider.notifier).selectStat(null);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnackBar('캡처 실패 — 잠시 후 다시 시도해주세요.');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar('이미지 변환 실패.');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      await _saveBytes(bytes);

      if (!mounted) return;
      _showSnackBar('갤러리에 저장됐습니다 🎉');
    } catch (e) {
      _logger.e('Image save failed', error: e);
      if (!mounted) return;
      _showSnackBar('저장 실패 — 갤러리 권한을 확인해주세요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveBytes(Uint8List bytes) async {
    final hasAccess = await Gal.hasAccess(toAlbum: false);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: false);
      if (!granted) {
        if (!mounted) return;
        _showSnackBar('갤러리 권한이 필요합니다.');
        return;
      }
    }
    await Gal.putImageBytes(bytes);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _openCustomizeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ShareCustomizeSheet(),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(runShareProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '공유 카드',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 캔버스 미리보기 ──────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: ShareCanvasWidget(
                    repaintKey: _repaintKey,
                    data: widget.data,
                    config: config,
                    backgroundImage: _backgroundImage,
                  ),
                ),
              ),
            ),

            // ── 하단 버튼 영역 ──────────────────────────────────────────────
            Container(
              color: AppColors.backgroundDark,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 배경 이미지 + 커스텀 버튼
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineButton(
                          icon: Icons.image_outlined,
                          label: '배경 선택',
                          onTap: _pickImage,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _OutlineButton(
                          icon: Icons.tune_rounded,
                          label: '커스텀',
                          onTap: _openCustomizeSheet,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveImage,
                      icon: _isSaving
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.download_rounded, size: 20.r),
                      label: Text(
                        _isSaving ? '저장 중...' : '이미지 저장',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 보조 위젯 ──────────────────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18.r),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
