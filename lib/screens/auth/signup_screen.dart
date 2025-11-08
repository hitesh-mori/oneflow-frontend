import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'mobile/signup_mobile.dart';
import 'tablet/signup_tablet.dart';
import 'desktop/signup_desktop.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => const SignupMobile(),
      tablet: (BuildContext context) => const SignupTablet(),
      desktop: (BuildContext context) => const SignupDesktop(),
    );
  }
}
