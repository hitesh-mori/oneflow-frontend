import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/profile_mobile.dart';
import 'tablet/profile_tablet.dart';
import 'desktop/profile_desktop.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const ProfileMobile(),
      tablet: (BuildContext context) => const ProfileTablet(),
      desktop: (BuildContext context) => const ProfileDesktop(),
    );
  }
}
