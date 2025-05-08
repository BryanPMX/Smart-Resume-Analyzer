// lib/screens/upload_screen.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/resume.dart';
import '../providers/resume_provider.dart';
import '../services/pdf_parser.dart';
import '../services/ocr_services.dart';
import '../services/scoring_service.dart';
import '../widgets/scanning_animation.dart';
import 'analysis_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  File? _pickedFile;
  String? _sourceType; // 'pdf' or 'camera'
  bool _isScanning = false;
  bool _isAnalyzing = false;
  bool _cancelRequested = false;

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Web PDF upload not implemented.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result?.files.single.path == null) return;

    final file = File(result!.files.single.path!);
    if (await file.length() > 5 * 1024 * 1024) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF exceeds 5 MB limit.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _sourceType = 'pdf';
    });
  }

  Future<void> _scanWithCamera() async {
    final messenger = ScaffoldMessenger.of(context);
    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Camera not supported on web.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Camera permission denied.'),
          backgroundColor: Colors.grey,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
            textColor: Colors.black87,
          ),
        ),
      );
      return;
    }

    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;

    final file = File(photo.path);
    if (await file.length() > 5 * 1024 * 1024) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Image exceeds 5 MB limit.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    setState(() {
      _pickedFile = file;
      _sourceType = 'camera';
    });
  }

  Future<void> _startScanThenAnalyze() async {
    if (_pickedFile == null || _isScanning || _isAnalyzing) return;

    setState(() => _isScanning = true);
    _cancelRequested = false;

    try {
      await _scanController.forward(from: 0).orCancel;
    } catch (_) {
      // cancelled
    }
    if (_cancelRequested) {
      setState(() => _isScanning = false);
      return;
    }
    setState(() => _isScanning = false);

    setState(() => _isAnalyzing = true);
    try {
      final text = (_sourceType == 'pdf')
          ? await PdfParserService.extractText(_pickedFile!)
          : await OcrService.extractText(_pickedFile!);

      if (_cancelRequested) throw Exception('Cancelled');

      final resume = Resume(
        fileName: _pickedFile!.path.split(Platform.pathSeparator).last,
        fullText: text,
        file: _pickedFile,
      );
      final scored = ScoringService.analyze(resume, enableLogging: true);
      context.read<ResumeViewModel>().updateResume(scored);

      if (!mounted || _cancelRequested) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('Cancelled')
              ? 'Analysis cancelled.'
              : 'Failed to analyze resume.'),
          backgroundColor: Colors.grey,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isScanning || _isAnalyzing) {
      _cancelRequested = true;
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Smart Resume Analyzer',
            style: GoogleFonts.merriweather(
              color: const Color(0xFF1E88E5),
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Source pick buttons...
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Upload PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanWithCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Camera'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Preview + overlay
              Expanded(
                child: _pickedFile == null
                    ? Center(
                  child: Text(
                    'Please select a PDF or scan via camera.',
                    style: GoogleFonts.merriweather(
                      color: Colors.black54,
                    ),
                  ),
                )
                    : Stack(
                  children: [
                    Positioned.fill(
                      child: _sourceType == 'pdf'
                          ? PDFView(filePath: _pickedFile!.path)
                          : Image.file(_pickedFile!,
                          fit: BoxFit.contain),
                    ),

                    if (_isScanning)
                      Positioned.fill(
                        child: ScanningAnimation(
                          duration: const Duration(seconds: 5),
                          beamHeight: 30.0,
                          beamColor: Colors.white,
                          dimBackground: true,
                        ),
                      ),

                    if (_isAnalyzing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_pickedFile != null &&
                      !_isScanning &&
                      !_isAnalyzing)
                      ? _startScanThenAnalyze
                      : null,
                  child: Text(
                    _isScanning
                        ? 'Scanning…'
                        : _isAnalyzing
                        ? 'Analyzing…'
                        : 'Start Analysis',
                    style: GoogleFonts.merriweather(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}