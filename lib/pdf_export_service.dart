// pdf_export_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';

class PdfExportService {
  static Future<void> exportNoteToPdf({
    required String textContent,
    required List<String> imagePaths,
  }) async {
    try {
      // Pre-load all images FIRST (before building PDF)
      final imageBytesList = <Uint8List>[];
      for (final imagePath in imagePaths) {
        final bytes = await _fileToBytes(imagePath);
        if (bytes.isNotEmpty) {
          imageBytesList.add(bytes);
        }
      }
      
      // Create PDF document
      final pdf = pdf_widgets.Document();
      
      // Add page with pre-loaded images
      pdf.addPage(
        pdf_widgets.Page(
          build: (pdf_widgets.Context context) {
            return pdf_widgets.Column(
              children: [
                pdf_widgets.Text(textContent),
                
                // Use pre-loaded images (no await in build method)
                for (final bytes in imageBytesList)
                  pdf_widgets.Image(pdf_widgets.MemoryImage(bytes)),
              ],
            );
          },
        ),
      );
      
      // Save and share
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'note_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      print('PDF Export Error: $e');
      rethrow;
    }
  }
  
  static Future<Uint8List> _fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return Uint8List(0);
    } catch (e) {
      print('Error loading file: $e');
      return Uint8List(0);
    }
  }
}