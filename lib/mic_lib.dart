import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

const dllPath = "./mic_lib/mic_lib.dll";
const bufferByteLength = 1024 * 1024 * 4;

class MicLib {
  final Pointer micLibPointer;
  final void Function(Pointer) freeMicLibFn;
  final int Function(Pointer, Pointer<Uint8>, int) getDevicesFn;
  final int Function(Pointer, Pointer<Uint8>, int) setDeviceFn;
  final int Function(Pointer, Pointer<Uint8>, int) selectedDeviceFn;
  final int Function(Pointer) startListeningFn;
  final void Function(Pointer) stopListeningFn;
  final int Function(Pointer) getSampleFormatFn;
  final int Function(Pointer, Pointer<Float>, int) readBufferFn;
  final int Function(Pointer) getErrorFn;

  final bufferPtr = malloc.allocate<Uint8>(bufferByteLength);
  MicLib({
    required this.micLibPointer,
    required this.freeMicLibFn,
    required this.getDevicesFn,
    required this.setDeviceFn,
    required this.selectedDeviceFn,
    required this.startListeningFn,
    required this.stopListeningFn,
    required this.getSampleFormatFn,
    required this.readBufferFn,
    required this.getErrorFn,
  });

  static Future<MicLib> load() async {
    final file = File(dllPath);
    final dynamicLibrary = DynamicLibrary.open(file.path);

    final instantiateFn =
        dynamicLibrary.lookupFunction<Pointer Function(), Pointer Function()>(
            "instantiate_mic_lib");

    final micLibPointer = instantiateFn();

    final freeMicLibFn = dynamicLibrary.lookupFunction<Void Function(Pointer),
        void Function(Pointer)>("free_mic_lib");

    final getDevicesFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer, Pointer<Uint8>, Uint64),
        int Function(Pointer, Pointer<Uint8>, int)>("get_devices");

    final setDeviceFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer, Pointer<Uint8>, Uint64),
        int Function(Pointer, Pointer<Uint8>, int)>("set_device");

    final selectedDeviceFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer, Pointer<Uint8>, Uint64),
        int Function(Pointer, Pointer<Uint8>, int)>("selected_device");

    final startListeningFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer), int Function(Pointer)>("start_listening");
    final stopListeningFn = dynamicLibrary.lookupFunction<
        Void Function(Pointer), void Function(Pointer)>("stop_listening");

    final getSampleFormatFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer), int Function(Pointer)>("get_sample_format");

    final readBufferFn = dynamicLibrary.lookupFunction<
        Int64 Function(Pointer, Pointer<Float>, Uint64),
        int Function(Pointer, Pointer<Float>, int)>("read_buffer");

    final getErrorFn = dynamicLibrary.lookupFunction<Int64 Function(Pointer),
        int Function(Pointer)>("get_error");

    return MicLib(
      micLibPointer: micLibPointer,
      freeMicLibFn: freeMicLibFn,
      getDevicesFn: getDevicesFn,
      setDeviceFn: setDeviceFn,
      selectedDeviceFn: selectedDeviceFn,
      startListeningFn: startListeningFn,
      stopListeningFn: stopListeningFn,
      getSampleFormatFn: getSampleFormatFn,
      readBufferFn: readBufferFn,
      getErrorFn: getErrorFn,
    );
  }

  void dispose() {
    freeMicLibFn(micLibPointer);
    malloc.free(bufferPtr);
  }

  List<String> getDevices() {
    late final List<String> devices;

    const len = bufferByteLength;
    // final optr = malloc.allocate<Uint8>(len);
    final optr = bufferPtr;

    final stringLen = getDevicesFn(micLibPointer, optr, len);
    if (stringLen != -1) {
      final devicesAsString = String.fromCharCodes(optr.asTypedList(stringLen));
      devices = devicesAsString.split('|').where((e) => e.isNotEmpty).toList();
    } else {
      devices = [];
    }

    // malloc.free(optr);

    debugPrint("devices: $devices");
    return devices;
  }

  String? getSelectedDevice() {
    const size = bufferByteLength;
    // final ptr = malloc.allocate<Uint8>(size);
    final ptr = bufferPtr;
    final result = selectedDeviceFn(micLibPointer, ptr, size);
    if (result < 0) {
      debugPrint("[extern selected_device] returned $result");
      // malloc.free(ptr);
      return null;
    }

    final device = utf8.decode(ptr.asTypedList(result));
    // final device = String.fromCharCodes(ptr.asTypedList(result));
    // malloc.free(ptr);

    return device;
  }

  bool setInputDevice(String device) {
    final buffer = utf8.encode(device);
    final lengthInBytes = buffer.length;
    // final dptr = malloc.allocate<Uint8>(lengthInBytes);
    final dPtr = bufferPtr;
    dPtr.asTypedList(lengthInBytes).setAll(0, buffer);
    debugPrint("Trying to set input device to $device");
    final result = selectedDeviceFn(micLibPointer, dPtr, lengthInBytes);

    // malloc.free(dptr);

    if (result < 0) {
      return false;
    } else {
      debugPrint("Set Input Device to $device");
      return true;
    }
  }

  bool startListening() {
    final result = startListeningFn(micLibPointer);
    if (result < 0) {
      debugPrint("Error Start Listening $result");
      return false;
    } else {
      return true;
    }
  }

  void stopListening() {
    stopListeningFn(micLibPointer);
  }

  int getFormat() {
    return getSampleFormatFn(micLibPointer);
  }

  List<double> readBuffer() {
    final error = getErrorFn(micLibPointer);
    if (error != -1) {
      stopListening();
      return [];
    }
    // const length = 1024 * 4;
    final length = bufferByteLength ~/ sizeOf<Float>();
    // final bPtr = malloc.allocate<Float>(length * sizeOf<Float>());
    final bPtr = bufferPtr.cast<Float>();
    final readLength = readBufferFn(micLibPointer, bPtr, length);
    final list = List<double>.from(bPtr.asTypedList(readLength));
    // malloc.free(bPtr);
    return list;
  }
}
