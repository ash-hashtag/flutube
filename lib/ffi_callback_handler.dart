import 'dart:ffi';

import 'package:flutter/material.dart';

typedef Listener = void Function(List<double>);

final _listeners = <Listener>[];

void addListener(Listener listener) {
  _listeners.add(listener);
}

void removeListener(Listener listener) {
  _listeners.remove(listener);
}

void onData(Pointer<Float> ptr, int size) {
  final list = List<double>.unmodifiable(ptr.asTypedList(size));
  debugPrint("data: $list");
  for (final listener in _listeners) {
    listener(list);
  }
}
