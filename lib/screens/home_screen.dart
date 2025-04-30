import 'package:flutter/material.dart';
import 'upload_screen.dart';

/// Home screen of the app which welcomes users and initiates the resume analysis flow.
/// Features a dynamic, animated background and interactive “Upload Resume” button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Animation state for the background gradient
  Alignment _begin = Alignment.topLeft;
  Alignment _end = Alignment.bottomRight;
  bool _toggled = false;

  // Scale state for the "Upload Resume" button
  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    // Kick off the background animation loop
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateBackground());
  }

  /// Toggles the gradient alignments every 5 seconds
  void _animateBackground() {
    if (!mounted) return;
    setState(() {
      _toggled = !_toggled;
      _begin = _toggled ? Alignment.topRight : Alignment.bottomLeft;
      _end = _toggled ? Alignment.bottomLeft : Alignment.topRight;
    });
    Future.delayed(const Duration(seconds: 5), _animateBackground);
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _buttonScale = 0.95);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _buttonScale = 1.0);
    // Navigate to the upload flow
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }

  void _onTapCancel() {
    setState(() => _buttonScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Full-screen animated gradient background
      body: AnimatedContainer(
        duration: const Duration(seconds: 5),
        onEnd: _animateBackground,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _begin,
            end: _end,
            colors: [Colors.indigo.shade200, Colors.indigo.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated headline fade-in
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, opacity, child) => Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                  child: Text(
                    'Optimize Your Resume',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Animated subheading slide-and-fade
                TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: const Offset(-0.2, 0), end: Offset.zero),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, offset, child) => Transform.translate(
                    offset: offset * 50,
                    child: Opacity(opacity: offset.dx.abs() < 0.01 ? 1 : 0.7, child: child),
                  ),
                  child: Text(
                    'Get an AI-powered review, personalized tips, '
                        'and an industry-aligned score.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Interactive Upload button with scale effect
                Center(
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    child: AnimatedScale(
                      scale: _buttonScale,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                color: Colors.indigo),
                            const SizedBox(width: 12),
                            Text(
                              'Upload Resume',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
