import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/mock_data.dart';

class IsmvccApp extends StatelessWidget {
  const IsmvccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MockData.store,
      builder: (context, _) => MaterialApp.router(
        title: 'Imran Sidhu Memorial VCC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
