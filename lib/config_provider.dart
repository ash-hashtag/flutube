import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConfigProvider {
  var threshold = 0.05;
  var switchDurationInMs = 300;

  ConfigProvider() {
    debugPrint("New Config");
  }

  @override
  String toString() =>
      " { ConfigProvider: { threshold: $threshold, switchDuration: $switchDurationInMs } } ";
}

class ThresholdHolder extends StatefulWidget {
  const ThresholdHolder({super.key});

  @override
  State<ThresholdHolder> createState() => _ThresholdHolderState();
}

class _ThresholdHolderState extends State<ThresholdHolder> {
  late final config = Provider.of<ConfigProvider>(context, listen: false);
  late final _thresholdController =
      TextEditingController(text: config.threshold.toString());
  late final _switchDurationController =
      TextEditingController(text: config.switchDurationInMs.toString());

  @override
  void dispose() {
    super.dispose();
    _thresholdController.dispose();
    _switchDurationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: TextField(
            controller: _thresholdController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            onChanged: onThresholdChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: TextField(
            controller: _switchDurationController,
            keyboardType: TextInputType.number,
            onChanged: onSwitchDurationChanged,
          ),
        ),
      ],
    );
  }

  void onThresholdChanged(String value) {
    final val = double.tryParse(value);
    if (val != null) {
      config.threshold = val;
      debugPrint("updated config: $config");
    }
  }

  void onSwitchDurationChanged(String value) {
    final val = int.tryParse(value);
    if (val != null) {
      config.switchDurationInMs = val;
      debugPrint("updated config: $config");
    }
  }
}
