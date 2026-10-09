import 'package:flutter/material.dart';

class AppColors {
  // Core Dark Palette
  static const Color bg = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color surfaceHighlight = Color(0xFF2A2A2A);
  
  static const Color border = Color(0xFF282828);
  static const Color borderInput = Color(0xFF727272);
  
  // Signature Green Accent
  static const Color accent = Color(0xFF1DB954);
  static const Color accentHover = Color(0xFF1ED760);
  static const Color onAccent = Color(0xFF000000);
  
  // Typography & Icons
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFB3B3B3);
  static const Color textSubtle = Color(0xFF6A6A6A);
  
  // Status & Feedback
  static const Color danger = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF1ED760);

  // Genre Card Gradient Colors
  static const List<Color> genreGradients = [
    Color(0xFFE13300), // Pop / Red-Orange
    Color(0xFF1E3264), // Hip-Hop / Blue
    Color(0xFFE91429), // Rock / Red
    Color(0xFF8D67AB), // Indie / Purple
    Color(0xFFE8115B), // Dance / Pink
    Color(0xFF006450), // Chill / Dark Teal
    Color(0xFF503750), // Jazz / Plum
    Color(0xFF477D95), // Classical / Slate
  ];
}
