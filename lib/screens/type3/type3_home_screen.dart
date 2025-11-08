import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/type3_home_mobile.dart';
import 'tablet/type3_home_tablet.dart';
import 'desktop/type3_home_desktop.dart';

class Type3HomeScreen extends StatelessWidget {
  const Type3HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const Type3HomeMobile(),
      tablet: (BuildContext context) => const Type3HomeTablet(),
      desktop: (BuildContext context) => const Type3HomeDesktop(),
    );
  }
}
