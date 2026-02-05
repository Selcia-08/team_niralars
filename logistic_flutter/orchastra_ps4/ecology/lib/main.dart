import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/absorption_provider.dart';
import 'providers/backhaul_provider.dart';
import 'providers/location_provider.dart';
import 'providers/earnings_provider.dart';
import 'providers/shipment_provider.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/driver/driver_dashboard_screen.dart';
import 'screens/shipper/shipper_dashboard_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.card,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  await StorageService().init();

  runApp(const EcoLogiqApp());
}

class EcoLogiqApp extends StatelessWidget {
  const EcoLogiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => AbsorptionProvider()),
        ChangeNotifierProvider(create: (_) => BackhaulProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
      ],
      child: MaterialApp(
        title: 'EcoLogiq',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper to handle auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading while initializing
        if (!auth.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 48,
                      color: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('EcoLogiq', style: AppTextStyles.heading1),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          );
        }

        // Check if logged in
        if (auth.isLoggedIn) {
          // Navigate based on role
          if (auth.isDriver) {
            return const DriverDashboardScreen();
          } else {
            return const ShipperDashboardScreen();
          }
        }

        // Show login screen
        return const PhoneLoginScreen();
      },
    );
  }
}
