import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BalanceConnecteeApp());
}

class BalanceConnecteeApp extends StatelessWidget {
  const BalanceConnecteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance Connectée',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF36B5FF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
