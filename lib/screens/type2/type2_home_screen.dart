import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/type2_home_mobile.dart';
import 'tablet/type2_home_tablet.dart';
import 'desktop/type2_home_desktop.dart';

class Type2HomeScreen extends StatelessWidget {
  const Type2HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const Type2HomeMobile(),
      tablet: (BuildContext context) => const Type2HomeTablet(),
      desktop: (BuildContext context) => const Type2HomeDesktop(),
    );
  }
}
