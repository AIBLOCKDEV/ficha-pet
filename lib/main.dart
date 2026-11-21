import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:ficha_pet/providers/auth_provider.dart';
import 'package:ficha_pet/providers/pet_provider.dart';
import 'package:ficha_pet/screens/auth_screen.dart';
import 'package:ficha_pet/screens/dashboard_screen.dart';
import 'package:ficha_pet/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PetProvider>(
          create: (_) => PetProvider(),
          update: (_, auth, petProvider) {
            final provider = petProvider ?? PetProvider();
            provider.setActiveUser(auth.currentUser);
            return provider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Ficha Pet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildTheme(
              seedIndex: auth.themeSeedIndex,
              brightness: Brightness.light,
            ),
            darkTheme: AppTheme.buildTheme(
              seedIndex: auth.themeSeedIndex,
              brightness: Brightness.dark,
            ),
            themeMode: auth.themeMode,
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: !auth.isInitialized
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : auth.isAuthenticated
                    ? const DashboardScreen()
                    : const AuthScreen(),
          );
        },
      ),
    );
  }
}
