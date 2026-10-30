import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/sofa_repository.dart';
import 'features/home/home_screen.dart';
import 'services/settings_service.dart';

/// Root widget: wires up the shared state and the theme.
class SofaArApp extends StatelessWidget {
  const SofaArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SofaRepository()..load()),
        ChangeNotifierProvider(create: (_) => SettingsService()..load()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
