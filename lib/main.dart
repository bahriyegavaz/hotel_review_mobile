import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: HotelReviewApp()));
}

/// ConsumerWidget çünkü routerProvider'a erişmemiz gerekiyor.
class HotelReviewApp extends ConsumerWidget {
  const HotelReviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // MaterialApp yerine MaterialApp.router - go_router kullanırken şart.
    return MaterialApp.router(
      title: 'Yorum Analiz Sistemi',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
    );
  }
}