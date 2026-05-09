import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
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

  static const Color _fieldBackground = Color(0xFFF4F4F4);
  static const Color _labelColor = Color(0xFF4A4A4A);
  static const Color _textColor = Color(0xFF222222);
  static const Color _hintColor = Color(0xFF8E8E8E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _fieldBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType ??
                (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            maxLines: maxLines,
            minLines: minLines,
            textAlignVertical:
                maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _hintColor,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        right: 8,
                        top: maxLines > 1 ? 12 : 0,
                      ),
                      child: suffixIcon,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
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
