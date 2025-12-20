import 'package:flutter/material.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/services/folder_service.dart';

class EditFolderPage extends StatefulWidget {
  final FolderService folderService;
  final Folder folder;
  const EditFolderPage({super.key, required this.folderService, required this.folder});

  @override
  State<EditFolderPage> createState() => _EditFolderPageState();
}

class _EditFolderPageState extends State<EditFolderPage> {
  String folderName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Folder"),
        actions: [IconButton(onPressed: () {
          _saveFolder();
        }, icon: const Icon(Icons.done))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Enter Folder Name',
          ),
          onChanged: (value) => folderName = value,
        ),
      ),
    );
  }

  void _saveFolder() {
    widget.folder.name = folderName;
    widget.folderService.updateFolder(widget.folder);
    Navigator.pop(context);
  }
}
