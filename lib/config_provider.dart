import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:provider/provider.dart';

class ConfigProvider {
  var _threshold = 0.05;

  double get threshold => _threshold;
  set threshold(double val) => _threshold = threshold;
}

class ThresholdHolder extends StatefulWidget {
  const ThresholdHolder({super.key});

  @override
  State<ThresholdHolder> createState() => _ThresholdHolderState();
}

class _ThresholdHolderState extends State<ThresholdHolder> {
  final _controller = TextEditingController(text: '0.05');

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        onChanged: (val) => Provider.of<ConfigProvider>(context, listen: false)
            .threshold = double.parse(val),
      ),
    );
  }
}
