// upload_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/resume.dart';
import '../providers/resume_provider.dart';
import '../services/pdf_parser.dart';
import '../services/ocr_services.dart';
import '../services/scoring_service.dart';
import 'analysis_screen.dart';

/// Screen for uploading a resume by selecting a PDF file or scanning with a camera, then running analysis.
/// Uses a vertical Stepper for a clear, interactive flow.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  int _currentStep = 0;
  File? _pickedFile;
  String? _fileName;
  String _sourceType = 'pdf'; // 'pdf' or 'camera'
  bool _isLoading = false;
  double _buttonScale = 1.0;

  /// Pick a PDF file from the device.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  /// Capture a resume image using the camera with permission handling.
  Future<void> _scanWithCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _pickedFile = File(image.path);
          _fileName = 'scanned_resume_${DateTime.now().millisecondsSinceEpoch}.png';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No image captured. Please try again.'),
              backgroundColor: Colors.indigo,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission denied. Please enable it in settings.'),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  /// Perform text extraction and analysis based on the selected source, then navigate.
  Future<void> _analyzeResume() async {
    if (_pickedFile == null) return;
    setState(() => _isLoading = true);
    try {
      final text = _sourceType == 'pdf'
          ? await PdfParserService.extractText(_pickedFile!)
          : await OcrService.extractText(_pickedFile!);
      final resume = Resume(fileName: _fileName ?? 'resume.pdf', fullText: text);
      final scored = ScoringService.analyze(resume);
      context.read<ResumeViewModel>().updateResume(scored);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalysisScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing resume: $e'),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_sourceType == 'pdf' && _pickedFile != null) {
        setState(() => _currentStep++);
      } else if (_sourceType == 'camera') {
        _scanWithCamera().then((_) {
          if (_pickedFile != null) {
            setState(() => _currentStep++);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please pick a PDF or scan with camera first.'),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_currentStep == 1) {
      if (_pickedFile != null) {
        setState(() => _currentStep++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No file selected. Please try again.'),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      _analyzeResume();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _onTapDown(TapDownDetails _) => setState(() => _buttonScale = 0.95);
  void _onTapUp(TapUpDetails _) {
    setState(() => _buttonScale = 1.0);
    _onStepContinue();
  }
  void _onTapCancel() => setState(() => _buttonScale = 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload & Analyze'),
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 2;
          final label = isLast ? 'Start Analysis' : 'Next';
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: label,
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      child: AnimatedScale(
                        scale: _buttonScale,
                        duration: const Duration(milliseconds: 100),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          icon: Icon(isLast ? Icons.analytics : Icons.arrow_forward),
                          label: Text(label),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            disabledBackgroundColor: Colors.indigo.shade200,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white54,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_currentStep > 0)
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: TextButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select File'),
            subtitle: _fileName != null ? Text(_fileName!) : null,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your resume source:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Pick PDF',
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.file_present),
                        label: const Text('Pick PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _pickedFile != null ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Source Selection'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select how to provide your resume:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text('Upload PDF File'),
                  value: 'pdf',
                  groupValue: _sourceType,
                  onChanged: (value) => setState(() => _sourceType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Scan with Camera'),
                  value: 'camera',
                  groupValue: _sourceType,
                  onChanged: (value) => setState(() => _sourceType = value!),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: StepState.indexed,
          ),
          Step(
            title: const Text('Confirm & Analyze'),
            content: _isLoading
                ? Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  const Text('Processing your resume...'),
                ],
              ),
            )
                : const Text(
              'Ready to analyze your resume? Tap "Start Analysis" to continue.',
            ),
            isActive: _currentStep >= 2,
            state: _isLoading ? StepState.editing : StepState.indexed,
          ),
        ],
      ),
    );
  }
}



