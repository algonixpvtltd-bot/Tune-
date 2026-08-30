import 'package:flutter/widgets.dart';

/// Local FontAwesome icon constants.
/// Font files are bundled in assets/fonts/fontawesome-free-6.4.0-desktop/
/// and registered in pubspec.yaml under FontAwesome-Solids / FontAwesome-Brands.
class AppIcons {
  AppIcons._();

  // --- Solid icons (FontAwesome-Solids) ---
  static const backwardStepSolid = IconData(0xe957, fontFamily: 'FontAwesome-Solids');
  static const chartSimpleSolid = IconData(0xe9fb, fontFamily: 'FontAwesome-Solids');
  static const downloadSolid = IconData(0xea93, fontFamily: 'FontAwesome-Solids');
  static const fileImportSolid = IconData(0xeaf9, fontFamily: 'FontAwesome-Solids');
  static const forwardStepSolid = IconData(0xeb28, fontFamily: 'FontAwesome-Solids');
  static const pauseSolid = IconData(0xec78, fontFamily: 'FontAwesome-Solids');
  static const playSolid = IconData(0xeccf, fontFamily: 'FontAwesome-Solids');
  static const plusSolid = IconData(0xecd7, fontFamily: 'FontAwesome-Solids');
  static const rotateRightSolid = IconData(0xed0e, fontFamily: 'FontAwesome-Solids');

  // --- Brand icons (FontAwesome-Brands) ---
  static const githubAltBrand = IconData(0xefb8, fontFamily: 'FontAwesome-Brands');
  static const lastfmBrand = IconData(0xeff6, fontFamily: 'FontAwesome-Brands');
  static const linkedinBrand = IconData(0xeffb, fontFamily: 'FontAwesome-Brands');
  static const xTwitterBrand = IconData(0xf0ea, fontFamily: 'FontAwesome-Brands');
}
