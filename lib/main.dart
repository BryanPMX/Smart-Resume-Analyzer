// The University of Texas at El Paso: Bryan Perez

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/resume_provider.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/analysis_screen.dart';
import 'utils/scoring_rules.dart';
import 'widgets/animated_gradient_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate scoring constants & regex patterns at startup.
  ScoringRules.initialize(enableLogging: true);

  // Global error handler for uncaught build/render errors.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Text(
          'Oops! Something went wrong.\n${details.exceptionAsString()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  };

  runApp(const SmartResumeAnalyzerApp());
}

/// The root widget of the Smart Resume Analyzer application.
/// Sets up providers, theming, routes, and the splash screen.
class SmartResumeAnalyzerApp extends StatelessWidget {
  const SmartResumeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResumeViewModel()),
      ],
      child: MaterialApp(
        title: 'Smart Resume Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(fontWeight: FontWeight.bold),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          }),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
          '/upload': (_) => const UploadScreen(),
          '/analysis': (_) => const AnalysisScreen(),
        },
      ),
    );
  }
}

/// A full‐screen splash that layers your animated gradient
/// behind the scaling app title before routing to HomeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    // Scale-in for the title.
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..forward();

    // Auto-navigate after 10 seconds.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1) animated gradient background filling the screen
          const AnimatedGradientBackground(),

          // 2) centered, scaling title on top
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleController.drive(
                  CurveTween(curve: Curves.easeOutBack),
                ),
                child: Text(
                  'Smart Resume Analyzer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    color: const Color(0xFF155C9C),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}






