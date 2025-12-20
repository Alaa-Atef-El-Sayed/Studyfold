import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyfold/desktop_view.dart';
import 'package:studyfold/folder_page.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/services/folder_service.dart';

class HomePage extends StatefulWidget {
  final FolderService folderService;
  final Set<String>? selectedItemIds;
  final String? initialFolderId;
  final void Function(bool done)? onCancel;
  const HomePage({
    super.key,
    required this.folderService,
    this.selectedItemIds,
    this.initialFolderId,
    this.onCancel,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text("Studyfold"))),
      body: _buildUI(),
      floatingActionButton: IconButton(
        onPressed: () {
          _handleCreateFolder();
          // widget.folderService.createFolder("test folder");
        },
        icon: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildUI() {
    return ValueListenableBuilder(
      valueListenable: widget.folderService.folderBox.listenable(),
      builder: (context, Box<Folder> box, widget) {
        final folders = box.values
            .where((folder) => folder.folderId == '0')
            .toList();

        if (folders.isEmpty) {
          return Center(child: Text("No folders yet, create one now!"));
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _buildFolderCard(folder, context);
          },
        );
      },
    );
  }

  Widget _buildFolderCard(Folder folder, BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          if (widget.initialFolderId == null) {
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
            
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => FolderPage(
                  folder: folder,
                  folderService: widget.folderService,
                  isMovingMode: true,
                  selectedItemIds: widget.selectedItemIds!,
                  onCancel: widget.onCancel,
                  initialFolderId: widget.initialFolderId,
                ),
              ),
            );
          }
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

  void _handleCreateFolder() {
    // widget.folderService.createFolder("New Folder");
    showDialog(
      context: context,
      builder: (context) {
        String folderName = "";
        String folderDescription = "";
        return AlertDialog(
          title: Text("Create New Folder"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Folder Name"),
                onChanged: (value) {
                  folderName = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: "Description (optional)",
                ),
                onChanged: (value) {
                  folderDescription = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  widget.folderService.createFolder(
                    folderName.trim(),
                    description: folderDescription.trim().isEmpty
                        ? null
                        : folderDescription.trim(),
                    folderId: '0',
                    positionX: 0,
                    positionY: 0,
                    page: 1,
                    pages: 4,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  // void _showCreateFolderDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => CreateFolderDialog(folderService: folderService),
  //   );
  // }
}
