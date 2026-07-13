import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bir widget'ı ProviderScope + MaterialApp içine sarıp ekrana basar.
///
/// Her testte bu boilerplate'i tekrar yazmak yerine tek yerde tutuyoruz.
/// `overrides` ile gerçek repository'lerin yerine stub'ları koyuyoruz.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
          // Testlerde animasyonları hızlandırmaya gerek yok, pumpAndSettle halleder.
        ),
      ),
    );
  }
}