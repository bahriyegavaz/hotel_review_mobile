import 'package:flutter/material.dart';

/// Uygulama açılışında saklı token okunurken gösterilen ekran.
/// Bu okuma milisaniyeler sürer, ama olmasaydı kullanıcı bir an
/// login ekranını görüp sonra dashboard'a atlardı - kötü görünürdü.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}