import 'package:flutter/material.dart';
import 'package:flutube/mic_lib.dart';
import 'package:provider/provider.dart';

class WaveCustomPaint extends CustomPainter {
  final List<double> values;

  WaveCustomPaint(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final xUnits = values.length;

    final paint = Paint()..color = Colors.black;
    for (var i = 0; i < xUnits; i++) {
      final xOffset = i * width / xUnits;
      final yOffset = -values[i] * height + height / 2;

      canvas.drawLine(
          Offset(xOffset, height / 2), Offset(xOffset, yOffset), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class WavesPainter extends StatefulWidget {
  const WavesPainter({super.key});

  @override
  State<WavesPainter> createState() => _WavesPainterState();
}

class _WavesPainterState extends State<WavesPainter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(days: 24));

    final tween = Tween(begin: 0.0, end: 1.0);
    final animation = _animationController.drive(tween);
    animation.addListener(() {
      final soundValues =
          Provider.of<MicLib>(context, listen: false).readBuffer();
      setState(() {
        const size = 500;
        if (soundValues.length > size) {
          values = soundValues.sublist(
              soundValues.length - size, soundValues.length);
        } else {
          values.addAll(soundValues);
          if (values.length > size) {
            values = values.sublist(values.length - size, values.length);
          }
        }
      });
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  var values = <double>[];

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
            height: 60,
            width: 500,
            child: CustomPaint(
                painter: WaveCustomPaint(values), child: Container())));
  }
}
