import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/booking_confirmation_screen.dart';
import 'screens/activity_history_screen.dart';
import 'screens/food_order_confirmation_screen.dart';
import 'screens/food_order_screen.dart';
import 'screens/home_screen.dart';
import 'screens/location_search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pickup_confirmation_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/searching_driver_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/trip_screen.dart';
import 'services/firebase/analytics_service.dart';
import 'services/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  await FirebaseBootstrap.initialize();
  runApp(const RideBookingApp());
}

class RideBookingApp extends StatelessWidget {
  const RideBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xanh SM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B8C4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF7FAFA),
          foregroundColor: Color(0xFF062D1D),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xFF00B8C4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Color(0xFF00B8C4),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      navigatorObservers: [
        if (FirebaseBootstrap.isReady) AnalyticsService().observer,
      ],
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ActivityHistoryScreen.routeName: (_) => const ActivityHistoryScreen(),
        FoodOrderScreen.routeName: (_) => const FoodOrderScreen(),
        FoodOrderConfirmationScreen.routeName: (_) =>
            const FoodOrderConfirmationScreen(),
        LocationSearchScreen.routeName: (_) => const LocationSearchScreen(),
        PickupConfirmationScreen.routeName: (_) =>
            const PickupConfirmationScreen(),
        BookingConfirmationScreen.routeName: (_) =>
            const BookingConfirmationScreen(),
        SearchingDriverScreen.routeName: (_) => const SearchingDriverScreen(),
        TripScreen.routeName: (_) => const TripScreen(),
        RatingScreen.routeName: (_) => const RatingScreen(),
      },
    );
  }
}
