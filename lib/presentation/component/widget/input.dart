import 'package:flutter/material.dart';

class Input extends StatelessWidget {
  final String label;
  final Color? background;
  final TextEditingController controller;
  final Icon? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;

  const Input({
    super.key,
    required this.label,
    this.background,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser le thème si background n'est pas fourni
    final bgColor = background ?? Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: TextFormField(
        obscureText: obscureText,
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon,
          labelStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
          ),
          filled: background != null,
          fillColor: bgColor,
        ),
      ),
    );
  }
}