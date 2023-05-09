import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutube/mic_lib.dart';
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

class VtubePlayer extends StatefulWidget {
  final MicLib micLib;
  const VtubePlayer({super.key, required this.micLib});

  @override
  State<VtubePlayer> createState() => _VtubePlayerState();
}

class _VtubePlayerState extends State<VtubePlayer> {
  var hoverState = HoverState.outside;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: onMouseEnter,
      onExit: onMouseExit,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          color: Colors.blue,
          width: double.infinity,
          height: double.infinity,
          child: Text(hoverState.toString()),
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

  Future<void> start() async {
    final dir = await getApplicationSupportDirectory();
    final results = await Future.wait(
        fileNames.map((val) => File("${dir.path}/$val").exists()));
    for (var i = 0; i < results.length; i++) {
      if (!results[i]) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Missing File ${fileNames[i]}")));
        }
      }
    }

    widget.micLib.startListening(onData);
  }

  var text = "";
  void onData(Pointer<Float> ptr, int size) {
    final list = ptr.asTypedList(size);
    setState(() {
      text = list.toString();
    });
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          FutureBuilder(
              future: loadMicLib(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error loading MicLib: ${snapshot.error}");
                }
                if (snapshot.data != null) {
                  return InputDeviceSelector(micLib: snapshot.data!);
                }
                if (snapshot.connectionState == ConnectionState.done) {
                  return const Text("Error loading MicLib");
                }
                return const CircularProgressIndicator.adaptive();
              }),
          Padding(
            padding: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: start,
              child: const Text('start'),
            ),
          ),
        ]),
      ),
      body: const VtubePlayer(),
    );
  }

  Future<void> import() async {
    final dir = await getApplicationSupportDirectory();

    if (mounted) {
      await showDialog(
          context: context, builder: (_) => ImportDialog(dirPath: dir.path));
    }
  }

  Future<void> start() async {
    final dir = await getApplicationSupportDirectory();
    final results = await Future.wait(
        fileNames.map((val) => File("${dir.path}/$val").exists()));
    for (var i = 0; i < results.length; i++) {
      if (!results[i]) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Missing File ${fileNames[i]}")));
        }
      }
    }
  }

  Future<MicLib?> loadMicLib() async {
    micLib = await MicLib.load();
    return micLib;
  }

  MicLib? micLib;

  @override
  void dispose() {
    super.dispose();
    micLib?.dispose();
  }
}

const fileNames = [
  "open-eyes-open-mouth",
  "open-eyes-close-mouth",
  "close-eyes-open-mouth",
  "close-eyes-close-mouth",
];

class ImportDialog extends StatelessWidget {
  final String dirPath;
  const ImportDialog({super.key, required this.dirPath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(36),
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
                    filePath: "$dirPath/${fileNames[0]}"),
                ImportGridTile(
                    title: "Open Eyes Close Mouth",
                    filePath: "$dirPath/${fileNames[1]}"),
                ImportGridTile(
                    title: "Close Eyes Open Mouth",
                    filePath: "$dirPath/${fileNames[2]}"),
                ImportGridTile(
                    title: "Close Eyes Close Mouth",
                    filePath: "$dirPath/${fileNames[3]}"),
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

class InputDeviceSelector extends StatefulWidget {
  final MicLib micLib;
  const InputDeviceSelector({super.key, required this.micLib});

  @override
  State<InputDeviceSelector> createState() => _InputDeviceSelectorState();
}

class _InputDeviceSelectorState extends State<InputDeviceSelector> {
  List<DropdownMenuEntry<String>> getEntries() => widget.micLib
      .getDevices()
      .map((device) => DropdownMenuEntry(label: device, value: device))
      .toList();

  late var selectedValue = widget.micLib.getSelectedDevice();

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      dropdownMenuEntries: getEntries(),
      initialSelection: selectedValue,
      onSelected: selectInputDevice,
    );
  }

  void selectInputDevice(String? val) {
    if (val != null) {
      if (widget.micLib.setInputDevice(val)) {
        setState(() => selectedValue = val);
      }
    }
  }
}
