import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:studyfold/models/canvas.dart';
import 'package:studyfold/models/file.dart';
import 'package:studyfold/models/file_base.dart';
import 'package:studyfold/models/folder.dart';
import 'package:studyfold/models/pdf.dart';
import 'package:uuid/uuid.dart';

class BundleService {
  static Future<String?> exportBundle(
    List<FileBase> itemsToExport,
    String exportName,
  ) async {
    try {
      await Permission.storage.request().isGranted;

      // 1. Convert all items to JSON
      final List<Map<String, dynamic>> entitiesJson = itemsToExport
          .map((e) => e.toJson())
          .toList();

      final Map<String, dynamic> manifest = {
        'version': 1,
        'entities': entitiesJson,
      };

      // 2. Create the Archive in RAM
      final archive = Archive();
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      // 3. Collect and attach all physical assets!
      // Using a Set prevents adding the same image twice if copied
      Set<String> allAssetPaths = {};
      for (var item in itemsToExport) {
        allAssetPaths.addAll(item.getAssetPaths());
      }

      for (String path in allAssetPaths) {
        final file = File(path);
        if (file.existsSync()) {
          final fileName = file.uri.pathSegments.last;
          final fileBytes = file.readAsBytesSync();

          // Add to the 'files/' directory inside the zip
          archive.addFile(
            ArchiveFile('files/$fileName', fileBytes.length, fileBytes),
          );
        }
      }

      // 4. Encode and Save the ZIP
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) throw Exception("Failed to encode zip");

      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) directory.createSync(recursive: true);

      final zipPath = '${directory.path}/StudyFold_$exportName.sfold';
      await File(zipPath).writeAsBytes(zipBytes, flush: true);

      return zipPath;
    } catch (e) {
      print("❌ EXPORT FAILED: $e");
      return null;
    }
  }

  static Future<bool> importBundle(
    String zipFilePath,
    String baseFolderId,
  ) async {
    try {
      final bytes = File(zipFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final manifestArchiveFile = archive.findFile('manifest.json');
      if (manifestArchiveFile == null) {
        throw Exception("Invalid .sfold file: No manifest.json");
      }

      final manifestString = utf8.decode(
        manifestArchiveFile.content as List<int>,
      );
      final Map<String, dynamic> manifest = jsonDecode(manifestString);

      final appDir = await getApplicationDocumentsDirectory();

      for (var archiveFile in archive) {
        if (archiveFile.isFile && archiveFile.name.startsWith('files/')) {
          final fileName = archiveFile.name.split('/').last;
          final newFilePath = '${appDir.path}/$fileName';

          final newFile = File(newFilePath);
          await newFile.writeAsBytes(
            archiveFile.content as List<int>,
            flush: true,
          );
        }
      }

      final List<dynamic> entities = manifest['entities'];
      final Map<String, String> idMap = {};

      for (var json in entities) {
        if (json['id'] != null) {
          idMap[json['id']] = const Uuid().v4();
        }
      }

      for (var json in entities) {
        final String type = json['type'];
        final String oldId = json['id'];

        if (oldId == null) continue;

        final String newId = idMap[oldId]!;
        final String? oldFolderId = json['folderId'];

        final String targetFolderId =
            (oldFolderId == null ||
                oldFolderId == '0' ||
                !idMap.containsKey(oldFolderId))
            ? baseFolderId
            : idMap[oldFolderId]!;

        switch (type) {
          case 'folder':
            final folder = Folder.fromJson(
              json: json,
              id: newId,
              folderId: targetFolderId,
            );
            await Hive.box<Folder>('folders').put(folder.id, folder);
            break;

          case 'pdf':
            final pdf = Pdf.fromJson(
              json: json,
              assetsDirPath: appDir.path,
              id: newId,
              folderId: targetFolderId,
            );
            _createFile(
              parentId: newId,
              filepath: '${appDir.path}/${json['filepath']}',
            );
            await Hive.box<Pdf>('pdfs').put(pdf.id, pdf);
            break;

          case 'canvas':
            final canvas = Canvas.fromJson(
              json: json,
              assetsDirPath: appDir.path,
              id: newId,
              folderId: targetFolderId,
            );
            // NOTE: Inside Canvas.fromJson, make sure you do:
            // elements.map((e) => CanvasElement.fromJson(e, generateNewId: true))
            await Hive.box<Canvas>('canvases').put(canvas.id, canvas);
            break;

          default:
            break;
        }
      }

      // print("✅ Import Successful!");
      return true;
    } catch (e, stacktrace) {
      // print("❌ IMPORT FAILED: $e");
      // print(stacktrace);
      return false;
    }
  }

  static void _createFile({
    required String parentId,
    required String filepath,
  }) async {
    final file = HiveFile(
      id: const Uuid().v4(),
      parentId: parentId,
      filepath: filepath,
    );
    await Hive.box<HiveFile>('files').put(file.id, file);
  }

  // Future<String> exportBundleA(String canvasId) async {
  //   final tempDir = await getTemporaryDirectory();
  //   final bundleDir = Directory('${tempDir.path}/export_bundle_$canvasId');
  //   if (bundleDir.existsSync()) bundleDir.deleteSync(recursive: true);
  //   bundleDir.createSync();

  //   final filesDir = Directory('${bundleDir.path}/files');
  //   filesDir.createSync();

  //   final filesBox = Hive.box<HiveFile>('files');
  //   final relatedFiles = filesBox.values
  //       .where((f) => f.parentId == canvasId)
  //       .toList();

  //   List<Map<String, dynamic>> exportedFilesJson = [];

  //   for (var hiveFile in relatedFiles) {
  //     final physicalFile = File(hiveFile.filepath);

  //     if (physicalFile.existsSync()) {
  //       final fileName = physicalFile.uri.pathSegments.last;

  //       physicalFile.copySync('${filesDir.path}/$fileName');

  //       exportedFilesJson.add(hiveFile.toJson(exportFileName: fileName));
  //     }
  //   }

  //   final Map<String, dynamic> manifest = {
  //     'version': 1,
  //     'canvasId': canvasId,
  //     'files': exportedFilesJson,
  //   };

  //   final manifestFile = File('${bundleDir.path}/manifest.json');
  //   await manifestFile.writeAsString(jsonEncode(manifest));

  //   final encoder = ZipFileEncoder();
  //   final zipPath = '${tempDir.path}/Canvas_$canvasId.sfold';
  //   encoder.create(zipPath);
  //   encoder.addDirectory(bundleDir);
  //   encoder.close();

  //   bundleDir.deleteSync(recursive: true);

  //   return zipPath;
  // }

  // Future<void> importBundle(String zipFilePath) async {
  //   final tempDir = await getTemporaryDirectory();
  //   final unzipDir = Directory('${tempDir.path}/import_temp');
  //   if (unzipDir.existsSync()) unzipDir.deleteSync(recursive: true);

  //   final bytes = File(zipFilePath).readAsBytesSync();
  //   final archive = ZipDecoder().decodeBytes(bytes);
  //   extractArchiveToDisk(archive, unzipDir.path);

  //   final manifestFile = File('${unzipDir.path}/manifest.json');
  //   final manifest = jsonDecode(manifestFile.readAsStringSync());

  //   final appDir = await getApplicationDocumentsDirectory();
  //   final appFilesDir = Directory('${appDir.path}/studyfold_assets');
  //   if (!appFilesDir.existsSync()) appFilesDir.createSync();

  //   final filesBox = Hive.box<HiveFile>('files');

  //   final List<dynamic> filesJson = manifest['files'];

  //   for (var json in filesJson) {
  //     final String fileName = json['filepath'];

  //     final bundledFile = File('${unzipDir.path}/files/$fileName');

  //     final newPermanentPath = '${appFilesDir.path}/$fileName';

  //     if (bundledFile.existsSync()) {
  //       bundledFile.copySync(newPermanentPath);

  //       final restoredHiveFile = HiveFile.fromJson(
  //         json,
  //         newAbsolutePath: newPermanentPath,
  //       );

  //       await filesBox.put(restoredHiveFile.id, restoredHiveFile);
  //     }
  //   }

  //   unzipDir.deleteSync(recursive: true);
  // }
}
