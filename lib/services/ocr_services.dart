// services/ocr_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

/// A service for extracting text from resume images using OCR.
/// Currently provides a simulated implementation; replace with a real OCR library (e.g., Tesseract, Google Vision API) for production use.
class OcrService {
  /// Extracts text from an image file using OCR.
  ///
  /// [image] The image file captured from the camera.
  ///
  /// Returns a [Future<String>] containing the extracted text.
  ///
  /// Throws an [Exception] if the image cannot be processed.
  ///
  /// Note: This is a placeholder implementation that simulates OCR with a delay and returns mock text.
  /// In a production environment, integrate a real OCR solution and handle additional edge cases (e.g., unreadable images).
  static Future<String> extractText(File image) async {
    // Validate image file
    if (!image.existsSync()) {
      throw Exception('Image file does not exist: ${image.path}');
    }

    // Simulate OCR processing time (2-4 seconds for realism)
    await Future.delayed(Duration(seconds: math.Random().nextInt(2) + 2));

    // Simulate a failure case (e.g., 10% chance of unreadable image)
    if (math.Random().nextDouble() < 0.1) {
      throw Exception('Unable to extract text: Image quality too low or content unreadable.');
    }

    // Mock resume text for testing, formatted to match expected input for SectionDetectorService
    return '''
==SECTION==
Personal Information
John Doe
john.doe@email.com
(123) 456-7890
linkedin.com/in/johndoe
github.com/johndoe

==SECTION==
Summary
Motivated software developer with 3 years of experience in building scalable applications.

==SECTION==
Experience
Software Engineer, Tech Corp (2022-Present)
- Developed RESTful APIs using Python and Flask
- Optimized database queries, improving performance by 20%

==SECTION==
Education
B.S. in Computer Science, University of Example (2022)
''';
  }
}