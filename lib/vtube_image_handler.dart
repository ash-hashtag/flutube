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

  late final config = Provider.of<ConfigProvider>(context, listen: false);
  late final micLib = Provider.of<MicLib>(context, listen: false);

  var eyesOpen = true;
  var mouthOpen = false;

  ImageState getState() {
    if (eyesOpen) {
      if (mouthOpen) {
        return ImageState.openEyesOpenMouth;
      } else {
        return ImageState.openEyesCloseMouth;
      }
    } else {
      if (mouthOpen) {
        return ImageState.closeEyesOpenMouth;
      } else {
        return ImageState.closeEyesCloseMouth;
      }
    }
  }

  void updateState() {
    final newState = getState();
    if (state != newState) {
      setState(() => state = newState);
      lastActionTimeStamp = DateTime.now();
    }
  }

  var lastActionTimeStamp = DateTime.now();

  void closeMouth() {
    if (DateTime.now().difference(lastActionTimeStamp).inMilliseconds >
        config.switchDurationInMs) {
      mouthOpen = false;
      updateState();
    }
  }

  void openMouth() {
    mouthOpen = true;
    updateState();
  }

  void listener() {
    final soundValues = micLib.readBuffer();
    if (soundValues.isEmpty) {
      closeMouth();
      return;
    }
    var metThreshold = false;
    final threshold = config.threshold;
    for (final val in soundValues) {
      if (val.abs() > threshold) {
        openMouth();
        metThreshold = true;
        break;
      }
    }
    if (!metThreshold) {
      closeMouth();
    }
  }

  String getInfo() {
    return config.toString();
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
