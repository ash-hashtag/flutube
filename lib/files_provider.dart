import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum ImageState {
  openEyesOpenMouth,
  openEyesCloseMouth,
  closeEyesOpenMouth,
  closeEyesCloseMouth;
}

class FileProvider extends ChangeNotifier {
  final Directory supportDirectory;

  late final List<File> _imageFiles;

  FileProvider({required this.supportDirectory}) {
    _imageFiles = ImageState.values
        .map((e) => File("${supportDirectory.path}/default/${e.name}"))
        .toList();
  }

  static Future<FileProvider> load() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final defaultImageDirectory = Directory("${supportDirectory.path}/default");
    await defaultImageDirectory.create(recursive: true);

    return FileProvider(supportDirectory: supportDirectory);
  }

  Iterable<File> getDefaultImages() {
    return _imageFiles;
  }

  File getDefaultImage(ImageState state) {
    return _imageFiles[state.index];
  }

  Future<void> updateImage(File file, ImageState state) async {
    await file.copy(_imageFiles[state.index].path);
    // notifyListeners();
  }

  Future<bool> areAllImagesImported() =>
      Future.wait(_imageFiles.map((e) => e.exists()))
          .then((vals) => vals.every((val) => val == true));
}
