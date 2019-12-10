import '../../library.dart';
import 'dart:ui' as ui;

enum FirebaseConnectionState { connected, disconnected }

/// An image widget for firebase that can be reused for all images in the app
class CustomImage extends StatefulWidget {
  /// Path of the image in Firebase Storage
  final String path;
  final Uint8List fallbackMemoryImage;
  /// The default is the theme's divider color
  final Color placeholderColor;
  final BoxFit fit;
  final double width;
  final double height;
  final Duration fadeInDuration;
  final void Function(double aspectRatio) onLoad;
  CustomImage(
    this.path, {
    Key key,
    this.fallbackMemoryImage,
    this.placeholderColor,
    this.fit: BoxFit.cover,
    this.width,
    this.height,
    this.fadeInDuration: const Duration(milliseconds: 200),
    this.onLoad,
  }) : super(key: key);

  @override
  _CustomImageState createState() => _CustomImageState();
}

class _CustomImageState extends State<CustomImage> {
  bool _init = false;
  ImageProvider _imageProvider;
  String _dirPath;
  bool _isFadingIn;

  void _resolveImage([Duration _]) {
    _imageProvider.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((image, synchronousCall) {
        if (mounted) widget.onLoad(image.image.width / image.image.height);
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _dirPath = Provider.of<Directory>(context)?.path;
      if (_dirPath == null) return;
      final filePath = widget.path.replaceAll('/', '-');
      final file = File('$_dirPath/$filePath');
      _isFadingIn =
          (widget?.fadeInDuration ?? Duration.zero) != Duration.zero;
      _imageProvider = FirebaseImage(
        file: file,
        path: widget.path,
      );
      if (widget.onLoad != null) {
        WidgetsBinding.instance.addPostFrameCallback(_resolveImage);
      }
      _init = true;
    }
  }

  @override
  void didUpdateWidget(CustomImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      final filePath = widget.path.replaceAll('/', '-');
      final file = File('$_dirPath/$filePath');
      _isFadingIn =
          (widget?.fadeInDuration ?? Duration.zero) != Duration.zero;
      _imageProvider = FirebaseImage(
        file: file,
        path: widget.path,
      );
      if (widget.onLoad != null) {
        WidgetsBinding.instance.addPostFrameCallback(_resolveImage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.placeholderColor,
      width: widget.width,
      height: widget.height,
      child: _dirPath == null
          ? null
          : _isFadingIn
              ? FadeInImage(
                  fadeInDuration: widget.fadeInDuration,
                  placeholder: MemoryImage(kTransparentImage),
                  image: _imageProvider,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                )
              : Image(
                  gaplessPlayback: true,
                  image: _imageProvider,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                ),
    );
  }
}

class FirebaseImage extends ImageProvider<FirebaseImage> {
  const FirebaseImage({
    @required this.file,
    @required this.path,
    this.scale = 1.0,
    this.debug = false,
  })  : assert(file != null || path != null),
        assert(scale != null);

  final File file;
  final String path;
  final double scale;
  final bool debug;

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(FirebaseImage key) {
    return MultiFrameImageStreamCompleter(
        codec: _loadAsync(key),
        scale: key.scale,
        informationCollector: () sync* {
          yield ErrorDescription('Image provider: $this');
          yield ErrorDescription('File path: ${file?.path}');
          yield ErrorDescription('Firebase path: $path');
        });
  }

  Future<ui.Codec> _loadAsync(FirebaseImage key) async {
    assert(key == this);

    Uint8List bytes;

    // Reads from the local file.
    if (file != null && _ifFileExistsLocally()) {
      bytes = await _readFromFile();
    }

    // Reads from the network and saves it to the local file.
    else if (path != null && path.isNotEmpty) {
      bytes = await _downloadFromFirebaseAndSaveToFile();
    }

    // Empty file.
    if (bytes?.lengthInBytes == 0) bytes = null;

    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  bool _ifFileExistsLocally() => file.existsSync();

  Future<Uint8List> _readFromFile() async {
    if (debug) print("Reading image file: ${file?.path}");
    return await file.readAsBytes();
  }

  static final _firebaseStorage = FirebaseStorage.instance;

  Future<Uint8List> _downloadFromFirebaseAndSaveToFile() async {
    assert(path != null && path.isNotEmpty);
    if (debug) print("Fetching image from Firebase: $path");

    final bytes = await _firebaseStorage.ref().child(path).getData(10 << 20);
    if (bytes.lengthInBytes == 0) {
      throw Exception('Firebase Image is an empty file!');
    }
    if (file != null) saveImageToFile(bytes);

    return bytes;
  }

  void saveImageToFile(Uint8List bytes) async {
    if (debug) print("Saving image to file: ${file?.path}");
    file.writeAsBytes(bytes, flush: true);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final FirebaseImage typedOther = other;
    return path == typedOther.path &&
        file?.path == typedOther.file?.path &&
        scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(path, file?.path, scale);

  @override
  String toString() => '$runtimeType("${file?.path}", "$path", scale: $scale)';
}
