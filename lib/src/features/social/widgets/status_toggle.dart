import 'package:flutter/material.dart';

class StatusToggle extends StatelessWidget {
  const StatusToggle({
    super.key,
    required this.isSelected,
    required this.text,
    required this.onTap,
  });

  final bool isSelected;
  final String text;
  final VoidCallback onTap;

  static const Color _selectedBackground = Color(0xFFB33010);
  static const Color _selectedText = Colors.white;
  static const Color _unselectedBackground = Color(0xFFEFEFEF);
  static const Color _unselectedText = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: ShapeDecoration(
            color: isSelected ? _selectedBackground : _unselectedBackground,
            shape: const StadiumBorder(),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _selectedText : _unselectedText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
