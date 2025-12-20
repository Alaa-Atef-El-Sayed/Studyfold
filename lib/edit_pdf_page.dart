import 'package:flutter/material.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:studyfold/services/folder_service.dart';

class EditPdfPage extends StatefulWidget {
  final FolderService folderService;
  final Pdf pdf;
  const EditPdfPage({super.key, required this.folderService, required this.pdf});

  @override
  State<EditPdfPage> createState() => _EditPdfPageState();
}

class _EditPdfPageState extends State<EditPdfPage> {
  String pdfName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit PDF"),
        actions: [IconButton(onPressed: () {
          _savePdf();
        }, icon: const Icon(Icons.done))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Enter PDF Name',
          ),
          onChanged: (value) => pdfName = value,
        ),
      ),
    );
  }

  void _savePdf() {
    widget.pdf.title = pdfName;
    widget.folderService.updatePdf(widget.pdf);
    Navigator.pop(context);
  }
}
