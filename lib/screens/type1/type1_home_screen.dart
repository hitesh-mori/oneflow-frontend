import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/type1_home_mobile.dart';
import 'tablet/type1_home_tablet.dart';
import 'desktop/type1_home_desktop.dart';

class Type1HomeScreen extends StatelessWidget {
  const Type1HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const Type1HomeMobile(),
      tablet: (BuildContext context) => const Type1HomeTablet(),
      desktop: (BuildContext context) => const Type1HomeDesktop(),
    );
  }
}
