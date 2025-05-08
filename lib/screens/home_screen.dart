// The University of Texas at El Paso: Bryan Perez

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'upload_screen.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_gradient_background.dart';

/// Home screen of the Smart Resume Analyzer app (Modern Academic Design).
///
/// Features:
/// - Animated gradient background for a dynamic visual effect
/// - Neutral academic color palette
/// - Animated headline and subheading for engaging introduction
/// - Enhanced “About” section with icons and separators in a dropdown
/// - Fixed upload button at the bottom center for easy access
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _buttonScale = 1.0;
  double _aboutOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade in the About section after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _aboutOpacity = 1.0);
    });
  }

  void _onTapDown(TapDownDetails _) => setState(() => _buttonScale = 0.95);
  void _onTapUp(TapUpDetails _) {
    setState(() => _buttonScale = 1.0);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
  }

  void _onTapCancel() => setState(() => _buttonScale = 1.0);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          const AnimatedGradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              minimum: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.06,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App title
                          Text(
                            'Smart Resume Analyzer',
                            style: GoogleFonts.merriweather(
                              color: const Color(0xFF155C9C),
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Animated headline
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              builder: (ctx, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: Text(
                                'Optimize Your Resume',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.merriweather(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Animated subheading
                          Center(
                            child: TweenAnimationBuilder<Offset>(
                              tween: Tween(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOut,
                              builder: (ctx, offset, child) => Opacity(
                                opacity: 1.0 - offset.dy.abs(),
                                child: Transform.translate(
                                  offset: Offset(0, offset.dy * 40),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                'Leverage data-driven insights and industry aligned scoring to elevate your resume’s impact. '
                                    'Get precise, actionable feedback on clarity, structure, and keywords tailored to your field.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.merriweather(
                                  color: const Color(0xFF454545),
                                  fontSize: 16,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // About section
                          AnimatedOpacity(
                            opacity: _aboutOpacity,
                            duration: const Duration(milliseconds: 800),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(
                                      'About',
                                      style: GoogleFonts.merriweather(
                                        color: Color(0xFF000000),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    childrenPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                    children: [
                                      _aboutTile(
                                        icon: Icons.track_changes,
                                        title: 'Methodology',
                                        content:
                                        'We split your resume into seven key sections: Contact, Summary, '
                                            'Experience, Education, Skills, Projects, Certifications and score '
                                            'each against best-practice criteria.',
                                      ),
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                      _aboutTile(
                                        icon: Icons.school,
                                        title: 'Research',
                                        content:
                                        'Based on peer-reviewed studies on readability, action words, '
                                            'and ATS keyword matching to ensure data-backed scoring.',
                                      ),
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                      _aboutTile(
                                        icon: Icons.pie_chart,
                                        title: 'Scoring Breakdown',
                                        content:
                                        'Contact: 15 • Summary: 10 • Experience: 20 • Education: 15 • '
                                            'Skills: 20 • Projects: 15 • Certifications: 5',
                                      ),
                                      const Divider(height: 1, indent: 16, endIndent: 16),
                                      _aboutTile(
                                        icon: Icons.lightbulb,
                                        title: 'Major Detection',
                                        content:
                                        'The backend examines the Education section to identify your field of study and personalize skill suggestions accordingly;\n'
                                            'if it can’t determine a major, it defaults to a broader, general set of recommendations.',
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

                  // Upload button fixed at bottom center
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: GestureDetector(
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        child: AnimatedScale(
                          scale: _buttonScale,
                          duration: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_file,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload Resume',
                                  style: GoogleFonts.merriweather(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual tile for the About section with an icon, title, and content.
  Widget _aboutTile({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: GoogleFonts.merriweather(
          color: Colors.grey.shade900,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          content,
          style: GoogleFonts.merriweather(
            color: Colors.grey.shade700,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}