import 'package:flutter/material.dart';
import 'package:flutube/files_provider.dart';
import 'package:provider/provider.dart';

class VtubeImageHandler extends StatefulWidget {
  const VtubeImageHandler({super.key});

  @override
  State<VtubeImageHandler> createState() => _VtubeImageHandlerState();
}

class _VtubeImageHandlerState extends State<VtubeImageHandler> {
  late final images = Provider.of<FileProvider>(context, listen: false)
      .getDefaultImages()
      .toList();

  var state = ImageState.openEyesCloseMouth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}
