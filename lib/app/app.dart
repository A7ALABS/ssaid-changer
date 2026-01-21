import 'package:flutter/material.dart';

import 'package:update_device_id/screens/splash_screen.dart';
import 'package:update_device_id/theme/app_theme.dart';

class DeviceIdApp extends StatelessWidget {
  const DeviceIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSAID Changer',
      theme: AppTheme.build(),
      home: const SplashScreen(),
    );
  }
}
