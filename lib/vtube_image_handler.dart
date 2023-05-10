import 'package:flutter/material.dart';
import 'package:flutube/files_provider.dart';
import 'package:flutube/mic_lib.dart';
import 'package:flutube/sound_visualization.dart';
import 'package:provider/provider.dart';

import 'config_provider.dart';

class VtubeImageHandler extends StatefulWidget {
  const VtubeImageHandler({super.key});

  @override
  State<VtubeImageHandler> createState() => _VtubeImageHandlerState();
}

class _VtubeImageHandlerState extends State<VtubeImageHandler>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final images = Provider.of<FileProvider>(context, listen: false)
      .getDefaultImages()
      .toList();
  var values = List.filled(500, 0.0, growable: true);

  var state = ImageState.openEyesCloseMouth;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(days: 10000));
    final animation = _animationController.drive(Tween(begin: 0.0, end: 1.0));
    animation.addListener(listener);
    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  void listener() {
    final soundValues =
        Provider.of<MicLib>(context, listen: false).readBuffer();
    if (soundValues.isEmpty) {
      setState(() => state = ImageState.openEyesCloseMouth);
      return;
    }
    values.addAll(soundValues);
    values = values.sublist(values.length - 500, values.length);

    var metThreshold = false;
    final threshold =
        Provider.of<ConfigProvider>(context, listen: false).threshold;
    for (final val in soundValues) {
      if (val.abs() > threshold) {
        debugPrint("$val met threshold: $threshold");
        setState(() => state = ImageState.openEyesOpenMouth);
        metThreshold = true;
        break;
      }
    }
    if (!metThreshold) {
      setState(() => state = ImageState.openEyesCloseMouth);
    }
  }

  var allTimeMax = 0.0;
  var allTimeMin = 0.0;
  String getInfo() {
    var max = 0.0, min = 0.0;
    for (final val in values) {
      if (val < min) {
        min = val;
      } else if (val > max) {
        max = val;
      }
    }

    if (min < allTimeMin) {
      allTimeMax = min;
    }

    if (max > allTimeMax) {
      allTimeMax = min;
    }

    return "{ allTimeMax: $allTimeMax, allTimeMin: $allTimeMin, min: $min, max: $max }";
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: Colors.purple,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(getInfo()),
            Container(
                color: Colors.yellow,
                height: 100,
                width: 500,
                child: CustomPaint(
                    painter: WaveCustomPaint(values), child: Container())),
            Row(
              children: ImageState.values
                  .map((imageState) => ElevatedButton(
                      onPressed: () => setState(() => state = imageState),
                      child: Text(imageState.name)))
                  .toList(),
            ),
            Expanded(
              child: Image.file(
                images[state.index],
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
