import 'dart:ffi';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

const dllPath = "./mic_lib/mic_lib.dll";

class MicLib {
  final int Function(Pointer<Uint8>, int, Pointer<Uint8>) helloFn;
  final Pointer micLibPointer;
  final void Function(Pointer) freeMicLibFn;
  final int Function(Pointer, Pointer<Uint8>, int) getDevicesFn;
  final int Function(Pointer, Pointer<Uint8>, int) setDeviceFn;
  final int Function(Pointer, Pointer<Uint8>, int) selectedDeviceFn;
  final int Function(
      Pointer,
      Pointer<NativeFunction<Void Function(Pointer<Float>, Uint64)>>,
      Pointer<NativeFunction<Void Function()>>) startListeningFn;
  final void Function(Pointer) stopListeningFn;

  MicLib({
    required this.helloFn,
    required this.micLibPointer,
    required this.freeMicLibFn,
    required this.getDevicesFn,
    required this.setDeviceFn,
    required this.selectedDeviceFn,
    required this.startListeningFn,
    required this.stopListeningFn,
  });

  static Future<MicLib?> load() async {
    if (await File(dllPath).exists()) {
      final file = File(dllPath);
      final dynamicLibrary = DynamicLibrary.open(file.path);

      final helloFn = dynamicLibrary.lookupFunction<
          Int64 Function(Pointer<Uint8>, Uint64, Pointer<Uint8>),
          int Function(Pointer<Uint8>, int, Pointer<Uint8>)>("hello");

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
          Int64 Function(
              Pointer,
              Pointer<NativeFunction<Void Function(Pointer<Float>, Uint64)>>,
              Pointer<NativeFunction<Void Function()>>),
          int Function(
              Pointer,
              Pointer<NativeFunction<Void Function(Pointer<Float>, Uint64)>>,
              Pointer<NativeFunction<Void Function()>>)>("start_listening");
      final stopListeningFn = dynamicLibrary.lookupFunction<
          Void Function(Pointer), void Function(Pointer)>("stop_listening");

      return MicLib(
        helloFn: helloFn,
        micLibPointer: micLibPointer,
        freeMicLibFn: freeMicLibFn,
        getDevicesFn: getDevicesFn,
        setDeviceFn: setDeviceFn,
        selectedDeviceFn: selectedDeviceFn,
        startListeningFn: startListeningFn,
        stopListeningFn: stopListeningFn,
      );
    }

    return null;
  }

  String hello(String value) {
    final ptr = value.toNativeUtf8(allocator: malloc).cast<Uint8>();
    final optr = malloc.allocate<Uint8>(64);
    final result = helloFn(ptr, value.length, optr);
    final s = String.fromCharCodes(optr.asTypedList(result));

    malloc.free(ptr);
    malloc.free(optr);

    return s;
  }

  void dispose() {
    freeMicLibFn(micLibPointer);
  }

  List<String> getDevices() {
    late final List<String> devices;

    const len = 1024 * 1024;
    final optr = malloc.allocate<Uint8>(len);

    final stringLen = getDevicesFn(micLibPointer, optr, len);
    if (stringLen != -1) {
      final devicesAsString = String.fromCharCodes(optr.asTypedList(stringLen));
      devices = devicesAsString.split('|').where((e) => e.isNotEmpty).toList();
    } else {
      devices = [];
    }

    malloc.free(optr);

    return devices;
  }

  String? getSelectedDevice() {
    const size = 64;
    final ptr = malloc.allocate<Uint8>(size);
    final result = selectedDeviceFn(micLibPointer, ptr, size);
    if (result < 0) {
      debugPrint("[extern selected_device] returned $result");
      malloc.free(ptr);
      return null;
    }
    final device = String.fromCharCodes(ptr.asTypedList(result));
    malloc.free(ptr);

    return device;
  }

  bool setInputDevice(String device) {
    final buffer = Uint8List.fromList(device.codeUnits);
    final lengthInBytes = buffer.lengthInBytes;
    final dptr = malloc.allocate<Uint8>(lengthInBytes);
    final result = selectedDeviceFn(micLibPointer, dptr, lengthInBytes);

    malloc.free(dptr);

    if (result < 0) {
      return false;
    } else {
      return true;
    }
  }

  void startListening(void Function(Pointer<Float>, int) onData) {
    final fPtr =
        Pointer.fromFunction<Void Function(Pointer<Float>, Uint64)>(onData);

    final ePtr = Pointer.fromFunction<Void Function()>(onError);

    startListeningFn(micLibPointer, fPtr, ePtr);
  }
}

void onError() => debugPrint("Error during stream");
