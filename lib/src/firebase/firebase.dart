import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Bolt/src/images/transparent_image.dart';

enum FirebaseConnectionState { connected, disconnected }

class FirebaseImage extends ImageProvider<FirebaseImage> {
  final String path;
  final Uint8List fallbackMemoryImage;
  final double scale;
  final Duration timeout;
  const FirebaseImage(
    this.path, {
    this.fallbackMemoryImage,
    this.scale: 1.0,
    this.timeout: const Duration(seconds: 10),
  });

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: (_) sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<FirebaseImage>('Image key', key);
      },
    );
  }

  Future<ui.Codec> _loadAsync(FirebaseImage key) async {
    assert(key == this);
    final String pathName = key.path;
    if (pathName == null)
      return PaintingBinding.instance
          .instantiateImageCodec(fallbackMemoryImage ?? kTransparentImage);
    final String filePath = pathName.replaceAll('/', '-');
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/$filePath');
    final bool exists = await file.exists();
    Uint8List bytes;
    if (exists) {
      bytes = await file.readAsBytes();
    } else {
      try {
        bytes = await FirebaseStorage.instance
            .ref()
            .child(pathName)
            .getData(10 * 1024 * 1024)
            .timeout(key.timeout);
        file.writeAsBytes(bytes);
      } catch (error) {
        bytes = fallbackMemoryImage ?? kTransparentImage;
      }
    }
    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }
}
