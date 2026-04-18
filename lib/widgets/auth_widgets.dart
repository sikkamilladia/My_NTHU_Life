import 'package:flutter/material.dart';

Widget authInputField({
  required String label,
  required IconData icon,
  bool obscure = false,
  Widget? suffixIcon,
  required ValueChanged<String> onChanged,
}) {
  return Builder(
    builder: (context) {
      final tt = Theme.of(context).textTheme;
      return TextField(
        obscureText: obscure,
        onChanged: onChanged,
        style: tt.bodyMedium,
        cursorColor: const Color(0xFF7C3AED),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: tt.labelMedium,
          prefixIcon: Icon(icon, color: Colors.white30, size: 18),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );
    },
  );
}

Widget authPrimaryButton({
  required String label,
  required Color accent,
  required VoidCallback onTap,
}) {
  return Builder(
    builder: (context) {
      final tt = Theme.of(context).textTheme;
      return SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: Text(label, style: tt.labelLarge)),
          ),
        ),
      );
    },
  );
}

Widget authErrorBanner(String message) {
  return Builder(
    builder: (context) {
      final tt = Theme.of(context).textTheme;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: tt.bodySmall?.copyWith(color: const Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
