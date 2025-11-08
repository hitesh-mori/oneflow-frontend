import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/login_mobile.dart';
import 'tablet/login_tablet.dart';
import 'desktop/login_desktop.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const LoginMobile(),
      tablet: (BuildContext context) => const LoginTablet(),
      desktop: (BuildContext context) => const LoginDesktop(),
    );
  }
}
