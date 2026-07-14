import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: HotelReviewApp()));
}

class HotelReviewApp extends ConsumerWidget {
  const HotelReviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Yorum Analiz Sistemi',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // Açık ve koyu tema tanımlı; themeMode.system cihaz ayarını izler.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}