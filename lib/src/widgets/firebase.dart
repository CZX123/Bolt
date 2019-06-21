import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Bolt/src/images/transparent_image.dart';

enum FirebaseConnectionState { connected, disconnected }

// Custom FirebaseImage widget that can be reused for all images in the app
class FirebaseImage extends StatefulWidget {
  final String path;
  final Uint8List fallbackMemoryImage;
  final Duration timeout;
  final BoxFit fit;
  final Duration fadeInDuration;
  FirebaseImage(
    this.path, {
    Key key,
    this.fallbackMemoryImage,
    this.timeout: const Duration(seconds: 10),
    this.fit: BoxFit.cover,
    this.fadeInDuration: const Duration(milliseconds: 400),
  }) : super(key: key);

  _FirebaseImageState createState() => _FirebaseImageState();
}

class _FirebaseImageState extends State<FirebaseImage>
    with AutomaticKeepAliveClientMixin {
  MemoryImage _imageProvider;
  bool didUpdate = false;

  void fetchImageFromStorage(Map<String, Uint8List> imageMap) async {
    final String filePath = widget.path.replaceAll('/', '-');
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File('${dir.path}/$filePath');
    if (file.existsSync()) {
      Uint8List bytes = file.readAsBytesSync();
      setState(() => _imageProvider ??= MemoryImage(bytes));
      imageMap.addAll({widget.path: bytes});
    }
  }

  void fetchImageFromFirebase(Map<String, Uint8List> imageMap) async {
    try {
      Uint8List bytes = await FirebaseStorage.instance
          .ref()
          .child(widget.path)
          .getData(10 * 1024 * 1024)
          .timeout(widget.timeout);
      setState(() => _imageProvider ??= MemoryImage(bytes));
      imageMap.addAll({widget.path: bytes});
      final Directory dir = await getApplicationDocumentsDirectory();
      final String filePath = widget.path.replaceAll('/', '-');
      final File file = File('${dir.path}/$filePath');
      file.writeAsBytes(bytes);
    } catch (e) {
      setState(() => _imageProvider ??=
          MemoryImage(widget.fallbackMemoryImage ?? kTransparentImage));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map<String, Uint8List> imageMap =
        Provider.of<Map<String, Uint8List>>(context);
    if (widget.path == null) {
      _imageProvider =
          MemoryImage(widget.fallbackMemoryImage ?? kTransparentImage);
    } else if (imageMap.containsKey(widget.path)) { // If the provider already has the image ossciated with
      _imageProvider = MemoryImage(imageMap[widget.path]);
    } else {
      // These 2 functions below runs in parallel
      fetchImageFromStorage(imageMap);
      fetchImageFromFirebase(imageMap);
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _imageProvider = null;
      if (widget.path == null) {
        _imageProvider =
            MemoryImage(widget.fallbackMemoryImage ?? kTransparentImage);
      } else {
        didUpdate = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (didUpdate) {
      Map<String, Uint8List> imageMap =
          Provider.of<Map<String, Uint8List>>(context);
      if (imageMap.containsKey(widget.path)) {
        _imageProvider = MemoryImage(imageMap[widget.path]);
      } else {
        fetchImageFromStorage(imageMap);
        fetchImageFromFirebase(imageMap);
      }
      didUpdate = false;
    }
    super.build(context);
    return _imageProvider == null
        ? SizedBox()
        : widget.fadeInDuration == null ||
                widget.fadeInDuration == Duration.zero
            ? Image(
                gaplessPlayback: true,
                image: _imageProvider,
                fit: widget.fit,
              )
            : FadeInImage(
                fadeInDuration: widget.fadeInDuration,
                placeholder: MemoryImage(kTransparentImage),
                image: _imageProvider,
                fit: widget.fit,
              );
  }

  @override
  bool get wantKeepAlive => true;
}
