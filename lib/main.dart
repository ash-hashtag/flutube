import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum HoverState { inside, outside }

class _MyHomePageState extends State<MyHomePage> {
  var hoverState = HoverState.outside;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: onMouseEnter,
      onExit: onMouseExit,
      child: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          backgroundColor: Colors.green,
          elevation: 0,
          title: Row(children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                onPressed: import,
                child: const Text('import'),
              ),
            ),
          ]),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              color: Colors.blue,
              child: Text(hoverState.toString()),
            ),
          ),
        ),
      ),
    );
  }

  void onMouseEnter(PointerEnterEvent event) {
    setState(() => hoverState = HoverState.inside);
  }

  void onMouseExit(PointerExitEvent event) {
    setState(() => hoverState = HoverState.outside);
  }

  Future<void> import() async {
    // final result = await FilePicker.platform
    //     .pickFiles(type: FileType.image, allowMultiple: true);
    // if (result != null) {
    //   debugPrint(result.files.toString());
    // }
    final dir = await getApplicationDocumentsDirectory();

    if (mounted) {
      await showDialog(
          context: context, builder: (_) => ImportDialog(dirPath: dir.path));
    }
  }
}

class ImportDialog extends StatelessWidget {
  final String dirPath;
  const ImportDialog({super.key, required this.dirPath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              childAspectRatio: 2,
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 16,
              children: [
                ImportGridTile(
                    title: "Open Eyes Open Mouth",
                    filePath: "$dirPath/open-eyes-open-mouth"),
                ImportGridTile(
                    title: "Open Eyes Close Mouth",
                    filePath: "$dirPath/open-eyes-close-mouth"),
                ImportGridTile(
                    title: "Close Eyes Open Mouth",
                    filePath: "$dirPath/close-eyes-open-mouth"),
                ImportGridTile(
                    title: "Close Eyes Close Mouth",
                    filePath: "$dirPath/close-eyes-close-mouth"),
              ],
            ),
          ),
          Center(
            child: ElevatedButton(
              child: const Text("Done"),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}

class ImportGridTile extends StatefulWidget {
  final String title;
  final String filePath;
  const ImportGridTile(
      {super.key, required this.title, required this.filePath});

  @override
  State<ImportGridTile> createState() => _ImportGridTileState();
}

class _ImportGridTileState extends State<ImportGridTile> {
  late final file = File(widget.filePath);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: import,
      child: GridTile(
        footer: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
          child: ElevatedButton(
              onPressed: clear,
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStateColor.resolveWith((state) => Colors.red)),
              child: const Text("Clear")),
        ),
        header: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('${widget.title} ${Random().nextDouble()}'),
        ),
        child: FutureBuilder<Uint8List?>(
          future: getBytes(),
          builder: (context, snapshot) {
            return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.hardEdge,
                child: snapshot.data != null
                    ? Image.memory(snapshot.data!)
                    : snapshot.connectionState == ConnectionState.done
                        ? null
                        : const Center(
                            child: CircularProgressIndicator.adaptive()));
          },
        ),
      ),
    );
  }

  Future<Uint8List?> getBytes() async {
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  Future<void> import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      final newFile = result.files.first;
      final bytes = newFile.bytes;
      if (bytes != null) {
        await file.writeAsBytes(bytes, flush: true);
      } else {
        final path = newFile.path;
        if (path != null) {
          await File(path).copy(file.path);
        }
      }
      setState(() {});
    }
  }

  Future<void> clear() async {
    await file.delete();
    setState(() {});
  }
}
