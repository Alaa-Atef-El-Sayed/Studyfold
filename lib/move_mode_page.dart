import 'package:flutter/material.dart';
import 'package:studyfold/folder_page.dart';
import 'package:studyfold/home_page.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/services/folder_service.dart';

class MoveModePage extends StatefulWidget {
  final FolderService folderService;
  final Set<String> selectedItemIds;
  final String initialFolderId;
  const MoveModePage({
    super.key,
    required this.folderService,
    required this.selectedItemIds,
    required this.initialFolderId,
  });

  @override
  State<MoveModePage> createState() => _MoveModePageState();
}

class _MoveModePageState extends State<MoveModePage> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => HomePage(
            folderService: widget.folderService,
            selectedItemIds: widget.selectedItemIds,
            initialFolderId: widget.initialFolderId,
            onCancel: (done) {
              Navigator.of(context, rootNavigator: true).pop(done);
            },
          ),
        );
      },
    );
  }

  Widget _buildFolderCard(Folder folder, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderPage(
                folder: folder,
                folderService: widget.folderService,
                isMovingMode: false,
                selectedItemIds: {},
              ),
            ),
          );
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => DesktopView(
          //     notes: widget.folderService.getNotesInFolder(folder.id),
          //   )),
          // );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                folder.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              if (folder.description != null) ...[
                SizedBox(height: 4),
                Text(
                  folder.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
