import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/bookings_screen.dart';
import 'screens/login_screen.dart';
import 'state/auth_state.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthState();
  await auth.bootstrap();
  runApp(ParamountApp(auth: auth));
}

class ParamountApp extends StatelessWidget {
  const ParamountApp({super.key, required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: const _RootApp(),
    );
  }
}

class _RootApp extends StatelessWidget {
  const _RootApp();

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final colors =
        brightness == Brightness.dark ? AppColors.dark : AppColors.light;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colors.isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Paramount Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: colors.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: colors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.champagne,
          brightness: colors.isDark ? Brightness.dark : Brightness.light,
          primary: AppColors.champagne,
          surface: colors.surface,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData(
            brightness: colors.isDark ? Brightness.dark : Brightness.light,
          ).textTheme,
        ),
      ),
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (auth.loading) {
            return Scaffold(
              backgroundColor: colors.background,
              body: Center(
                child: CircularProgressIndicator(color: colors.champagne),
              ),
            );
          }
          if (auth.user == null) {
            return LoginScreen(colors: colors);
          }
          return BookingsScreen(colors: colors);
        },
      ),
    );
  }
}
