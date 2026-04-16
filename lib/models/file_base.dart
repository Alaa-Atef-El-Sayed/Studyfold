import 'package:studyfold/models/json_serializable.dart';

abstract class FileBase implements JsonSerializable {
  abstract final double positionX;
  abstract final double positionY;
  abstract String folderId;
  abstract final String id;
  abstract final int createdAt;

  List<String> getAssetPaths();
}
