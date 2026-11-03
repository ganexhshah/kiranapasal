import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/repositories/app_data_repository.dart';
import 'core/services/printing_service.dart';
import 'core/services/product_settings_service.dart';
import 'core/theme/theme.dart';
import 'features/splash/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initialize();
  await PrintingService.instance.init();
  await ProductSettingsService.instance.init();
  await AppDataRepository.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pasal365',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home ?? const SplashScreen(),
    );
  }
}
