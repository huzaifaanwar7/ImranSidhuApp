import 'package:flutter/material.dart';

/// Brand palette matched to the official Imran Sidhu Memorial VCC
/// App Design Proposal v2.0 (cream + navy + gold + ball red).
class AppColors {
  AppColors._();

  // Navy (primary brand)
  static const Color navy = Color(0xFF0F2447);
  static const Color navyDeep = Color(0xFF081735);
  static const Color navyLight = Color(0xFF1A356A);

  // Gold (accent)
  static const Color gold = Color(0xFFD4A845);
  static const Color goldBright = Color(0xFFE8BC5C);
  static const Color goldDeep = Color(0xFF9F7D2E);

  // Cream / editorial surfaces
  static const Color cream = Color(0xFFF7F2E6);
  static const Color creamSoft = Color(0xFFFBF8EE);
  static const Color willow = Color(0xFFE8DCB8);

  // Cricket ball
  static const Color ballRed = Color(0xFFC8202C);
  static const Color ballDeep = Color(0xFF8B1620);

  // Neutrals
  static const Color ink = Color(0xFF0A0F1F);
  static const Color grey = Color(0xFF6B7180);
  static const Color line = Color(0xFFE3DCC8);

  // Sponsor accents
  static const Color amasGreen = Color(0xFF1B8A3A);
  static const Color amasRed = Color(0xFFD6173E);
  static const Color pmBlue = Color(0xFF1D4FAA);
  static const Color pmYellow = Color(0xFFF5C518);
  static const Color pmRed = Color(0xFFE11E2C);

  // Aliases used through the codebase
  static const Color background = cream;
  static const Color surface = Colors.white;
  static const Color surfaceMuted = creamSoft;
  static const Color divider = line;
  static const Color textPrimary = ink;
  static const Color textSecondary = grey;
  static const Color textMuted = grey;
  static const Color cricketRed = ballRed;
  static const Color cricketRedDark = ballDeep;
  static const Color goldLight = goldBright;
  static const Color goldDark = goldDeep;
  static const Color emerald = amasGreen;
  static const Color royalBlue = pmBlue;
  static const Color textOnNavy = cream;
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color danger = Color(0xFFD92D20);
  static const Color info = Color(0xFF2E90FA);
  static const Color live = ballRed;
  static const Color upcoming = navyLight;
  static const Color completed = grey;
  static const Color runDot = grey;
  static const Color runSingle = navyLight;
  static const Color runFour = navy;
  static const Color runSix = ballRed;
  static const Color runWicket = ink;
  static const Color runExtra = gold;

  // Flat team-flag palettes (matches prototype flag-a..d colors)
  static const List<List<Color>> teamFlagPalettes = [
    [Color(0xFF2E7D32), Color(0xFF1B5E20)], // green (SW)
    [Color(0xFF1565C0), Color(0xFF0D47A1)], // blue (LB)
    [Color(0xFFC62828), Color(0xFF8E0000)], // red (KK)
    [Color(0xFFF57F17), Color(0xFFE65100)], // orange (PS)
    [Color(0xFF6A1B9A), Color(0xFF4A148C)], // purple (QG)
    [Color(0xFF00838F), Color(0xFF006064)], // teal (IU)
    [Color(0xFF5D4037), Color(0xFF3E2723)], // brown (MS)
    [Color(0xFF558B2F), Color(0xFF33691E)], // olive (FT)
  ];

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyDeep],
  );

  static const LinearGradient navyHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyDeep],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDeep, gold, goldBright],
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Colors.white, creamSoft],
  );

  static const LinearGradient liveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ballRed, ballDeep],
  );
}
