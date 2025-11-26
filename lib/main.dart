import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/screens/dashboard_screen.dart';
import 'package:ficha_pet/utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PetProvider()..loadPets(),
      child: MaterialApp(
        title: 'Ficha Pet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}

