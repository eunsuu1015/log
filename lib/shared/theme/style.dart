import 'package:flutter/material.dart';

class AppButtonStyle {
  static final ButtonStyle primaryButton = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
