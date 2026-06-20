import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class CustomInputField extends StatefulWidget {
  const CustomInputField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.suffixIcon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  static const Color _labelColor = AppColors.dMuted;
  static const Color _textColor = AppColors.dText;
  static const Color _hintColor = AppColors.dFaint;
  static const Color _background = AppColors.dCard2;
  static const Color _borderNormal = AppColors.dLine;
  static const Color _borderFocused = AppColors.dAccent;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;
    final radius = BorderRadius.circular(18.r);
    final borderColor = _isFocused ? _borderFocused : _borderNormal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _isFocused ? _borderFocused : _labelColor,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias, // 안쪽 TextField를 둥근 모서리에 맞춰 클리핑
          decoration: BoxDecoration(
            color: _background,
            borderRadius: radius,
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType ??
                (isMultiline ? TextInputType.multiline : TextInputType.text),
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            textAlignVertical:
                isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: _hintColor,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18.w,
                vertical: isMultiline ? 14.h : 0,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        right: 4.w,
                        top: isMultiline ? 12.h : 0,
                      ),
                      child: widget.suffixIcon,
                    )
                  : null,
              suffixIconConstraints: BoxConstraints(
                minWidth: 44.w,
                minHeight: 44.h,
              ),
              isCollapsed: !isMultiline,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
