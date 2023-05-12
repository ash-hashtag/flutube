import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutube/config_provider.dart';
import 'package:flutube/vtube_image_handler.dart';

import 'files_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutube/mic_lib.dart';
import 'package:provider/provider.dart';

void main() async {
  final micLib = await MicLib.load();
  final fileProvider = await FileProvider.load();
  final app = MultiProvider(providers: [
    Provider.value(value: micLib),
    Provider.value(value: ConfigProvider()),
    ChangeNotifierProvider.value(value: fileProvider),
  ], child: const MyApp());
  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutube',
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

class VtupePlayerBase extends StatefulWidget {
  const VtupePlayerBase({super.key});

  @override
  State<VtupePlayerBase> createState() => _VtupePlayerBaseState();
}

class _VtupePlayerBaseState extends State<VtupePlayerBase>
    with SingleTickerProviderStateMixin {
  var text = "";
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(days: 365));
    final tween = Tween(begin: 0.0, end: 1.0);
    final animation = _animationController.drive(tween);
    animation.addListener(listener);
    _animationController.forward();
  }

  void listener() {
    final list = Provider.of<MicLib>(context, listen: false).readBuffer();
    if (list.isNotEmpty) {
      setState(() {
        final maxValue = list.reduce((a, b) => a > b ? a : b);
        final minValue = list.reduce((a, b) => a < b ? a : b);
        final length = list.length;

        setState(
            () => text = "{ min: $minValue, max: $maxValue, length: $length }");
        debugPrint(text);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class VtubePlayer extends StatefulWidget {
  const VtubePlayer({super.key});

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                  onPressed: startListening, child: const Text("Start")),
              ElevatedButton(
                  onPressed: stopListening, child: const Text("Stop")),
              Text("{ hoverState: $hoverState, isListening: $isListening }"),
              if (Provider.of<FileProvider>(context, listen: false)
                  .getDefaultImages()
                  .every((el) => el.existsSync()))
                const Expanded(child: VtubeImageHandler())
              else
                const Text("Not All Images are imported"),
            ],
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

  var isListening = false;

  Future<void> startListening() async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final results = await Future.wait(
        fileProvider.getDefaultImages().map((val) => val.exists()));
    for (var i = 0; i < results.length; i++) {
      if (!results[i]) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Missing File ${ImageState.values[i]}")));
          return;
        }
      }
    }
    if (mounted) {
      final result =
          Provider.of<MicLib>(context, listen: false).startListening();
      if (result) setState(() => isListening = true);
    }
  }

  void stopListening() {
    Provider.of<MicLib>(context, listen: false).stopListening();
    setState(() => isListening = false);
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
          const ThresholdHolder(),
          Padding(
            padding: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: import,
              child: const Text('import'),
            ),
          ),
          const InputDeviceSelector(),
        ]),
      ),
      body: const VtubePlayer(),
    );
  }

  Future<void> import() async {
    await showDialog(context: context, builder: (_) => const ImportDialog());
  }
}

class ImportDialog extends StatelessWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
                mainAxisSpacing: 4,
                children: fileProvider
                    .getDefaultImages()
                    .map((file) => ImportGridTile(
                        title: file.path.split('/').last, filePath: file.path))
                    .toList()),
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
  const InputDeviceSelector({
    super.key,
  });

  @override
  State<InputDeviceSelector> createState() => _InputDeviceSelectorState();
}

class _InputDeviceSelectorState extends State<InputDeviceSelector> {
  List<DropdownMenuEntry<String>> getEntries() =>
      Provider.of<MicLib>(context, listen: false)
          .getDevices()
          .map((device) => DropdownMenuEntry(label: device, value: device))
          .toList();

  late var selectedValue =
      Provider.of<MicLib>(context, listen: false).getSelectedDevice();

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
      if (Provider.of<MicLib>(context, listen: false).setInputDevice(val)) {
        setState(() => selectedValue = val);
      }
    }
  }
}
