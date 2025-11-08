import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/auth_provider.dart';
import 'services/storage_service.dart';

String pageTitle = 'OneFlow';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load stored title from SharedPreferences
  final storedTitle = await StorageService.getPageTitle();
  if (storedTitle != null && storedTitle.isNotEmpty) {
    pageTitle = storedTitle;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(
          title: pageTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
