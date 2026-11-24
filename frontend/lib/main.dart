import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ekride_frontend/core/theme.dart';
import 'package:ekride_frontend/services/api_service.dart';
import 'package:ekride_frontend/services/app_settings_provider.dart';
import 'package:ekride_frontend/services/auth_provider.dart';
import 'package:ekride_frontend/services/ride_provider.dart';
import 'package:ekride_frontend/screens/auth_screen.dart';
import 'package:ekride_frontend/screens/main_screen.dart';

void main() {
  runApp(const EkRideApp());
}

class EkRideApp extends StatelessWidget {
  const EkRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => RideProvider(apiService)),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            title: appSettings.isBangla ? 'একরাইড - স্মার্ট স্টুডেন্ট রাইড-শেয়ারিং' : 'EkRide - Smart Student Ride-Sharing',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appSettings.themeMode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const MainScreen() : const AuthScreen();
  }
}
