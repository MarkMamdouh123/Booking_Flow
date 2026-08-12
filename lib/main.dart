import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/availability/availability_cubit.dart';
import 'cubits/booking/booking_cubit.dart';
import 'cubits/theme/theme_cubit.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';
import 'views/screens/main_navigation_screen.dart';
import 'views/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const BookingSystemApp());
}

class BookingSystemApp extends StatelessWidget {
  const BookingSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AvailabilityCubit()),
        BlocProvider(create: (_) => BookingCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Booking Management System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

/// Manages splash → home transition at the widget level,
/// completely bypassing Navigator so no Hero animations are triggered.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _splashDone = false;

  void _onSplashComplete() {
    setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _splashDone
          ? const MainNavigationScreen(key: ValueKey('home'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onComplete: _onSplashComplete,
            ),
    );
  }
}
