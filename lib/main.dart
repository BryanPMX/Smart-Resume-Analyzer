import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/resume_provider.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/analysis_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler to show a friendly UI on unexpected errors
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

          // Unified page transitions for a polished feel
          pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          }),
        ),

        // Use named routes for clarity and easy expansion
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

/// Simple splash screen with animated gradient, then navigates to Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Alignment _begin = Alignment.topLeft;
  Alignment _end = Alignment.bottomRight;

  @override
  void initState() {
    super.initState();
    // Animate gradient and then push HomeScreen
    Future.delayed(const Duration(milliseconds: 100), _animateGradient);
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  void _animateGradient() {
    setState(() {
      _begin = Alignment.bottomRight;
      _end = Alignment.topLeft;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _begin,
            end: _end,
            colors: [
              colors.primaryContainer,
              colors.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Smart Resume Analyzer',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontSize: 28,
            ),
          ),
        ),
      ),
    );
  }
}
