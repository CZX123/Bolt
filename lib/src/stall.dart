import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'stall_data.dart';
import 'order.dart';
import 'transparent_image/transparent_image.dart';
import 'firebase/firebase.dart';

class Stall extends StatefulWidget {
  final String name;
  final Animation<double> animation;
  final ScrollController scrollController;
  const Stall({
    Key key,
    @required this.name,
    @required this.animation,
    @required this.scrollController,
  }) : super(key: key);

  @override
  _StallState createState() => _StallState();
}

class _StallState extends State<Stall> {
  @override
  Widget build(BuildContext context) {
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              return SizedBox(
                height: widget.animation.value.clamp(0.0, double.infinity) *
                    windowPadding.top,
              );
            },
          ),
          StallQueue(
            stallName: widget.name,
            padding: const EdgeInsets.fromLTRB(0, 96, 0, 0),
          ),
          FlatButton(
            child: Text('Toggle View Order'),
            onPressed: () {
              Provider.of<ViewOrder>(context).toggle();
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 72.0),
            child: Wrap(
              spacing: 8.0,
              children: <Widget>[
                for (int i = 0; i < 10; i++) FoodItem(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StallQueue extends StatelessWidget {
  final String stallName;
  final EdgeInsetsGeometry padding;
  const StallQueue({
    @required this.stallName,
    this.padding = const EdgeInsets.symmetric(vertical: 24.0),
  });
  @override
  Widget build(BuildContext context) {
    return ProxyProvider<List<StallData>, int>(
      builder: (context, stallDataList, queue) {
        return stallDataList
            .firstWhere((stallData) => stallData.name == stallName,
                orElse: () => null)
            ?.queue;
      },
      child: Padding(
        padding: padding,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.accessibility,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Consumer<int>(
                      builder: (context, queue, child) => Container(
                            alignment: Alignment.center,
                            constraints: BoxConstraints(
                              minWidth: queue != null && queue > 99 ? 27 : 18,
                            ),
                            child: AnimatedSwitcher(
                              switchOutCurve:
                                  Interval(0.5, 1, curve: Curves.easeIn),
                              switchInCurve:
                                  Interval(0.5, 1, curve: Curves.easeOut),
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                queue?.toString() ?? '',
                                key: ValueKey<int>(queue),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text('people'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Consumer<int>(
                      builder: (context, queue, child) => Container(
                            alignment: Alignment.center,
                            constraints: BoxConstraints(
                              minWidth:
                                  queue != null && queue ~/ 1.5 > 99 ? 27 : 18,
                            ),
                            child: AnimatedSwitcher(
                              switchOutCurve:
                                  Interval(0.5, 1, curve: Curves.easeIn),
                              switchInCurve:
                                  Interval(0.5, 1, curve: Curves.easeOut),
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                queue != null ? '${queue ~/ 1.5}' : '',
                                key: ValueKey<int>(queue),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text('mins'),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Material(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Consumer<int>(
                    builder: (context, queue, child) => IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (queue != null) {
                              FirebaseDatabase.instance
                                  .reference()
                                  .child(
                                      'stalls/${stallName.toLowerCase()}/queue')
                                  .set(queue + 1);
                            }
                          },
                        ),
                  ),
                  const SizedBox(
                    width: 24.0,
                  ),
                  Consumer<int>(
                    builder: (context, queue, child) => IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (queue != null && queue > 0) {
                              FirebaseDatabase.instance
                                  .reference()
                                  .child(
                                      'stalls/${stallName.toLowerCase()}/queue')
                                  .set(queue - 1);
                            }
                          },
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StallImage extends StatefulWidget {
  final String stallName;
  final int index;
  final ValueNotifier<double> offsetNotifier;
  final Animation<double> defaultAnimation; // From CustomButtomSheet
  final Animation<double> animation;
  final PageController pageController;
  final bool last;
  const StallImage({
    Key key,
    @required this.stallName,
    @required this.index,
    @required this.offsetNotifier,
    @required this.defaultAnimation,
    @required this.animation,
    @required this.pageController,
    this.last: false,
  }) : super(key: key);

  @override
  _StallImageState createState() => _StallImageState();
}

class _StallImageState extends State<StallImage>
    with AutomaticKeepAliveClientMixin {
  ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((dir) {
      final String pathName = Provider.of<List<StallNameAndImage>>(context)
          .firstWhere((s) => s.name == widget.stallName)
          .image;
      final String filePath = pathName.replaceAll('/', '-');
      File file = File('${dir.path}/$filePath');
      file.exists().then((exists) {
        if (exists) {
          file.readAsBytes().then((data) {
            setState(() => _imageProvider = MemoryImage(data));
          });
        } else {
          if (Provider.of<FirebaseConnectionState>(context) ==
              FirebaseConnectionState.disconnected)
            setState(
                () => _imageProvider = AssetImage('assets/images/glitch.jpg'));
          else {
            FirebaseStorage.instance
                .ref()
                .child(pathName)
                .getData(10 * 1024 * 1024) // 10 MB max size.
                  ..timeout(Duration(seconds: 10))
                  ..catchError((error) {
                    //print(error);
                    setState(() => _imageProvider =
                        AssetImage('assets/images/glitch.jpg'));
                  })
                  ..then((data) {
                    setState(() => _imageProvider = MemoryImage(data));
                    file.writeAsBytes(data);
                  });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('${widget.stallName} Image Rebuilt');
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        double height;
        double y = 0;
        if (widget.animation.value < 0)
          height = widget.defaultAnimation.value *
                  MediaQuery.of(context).size.height +
              32;
        else {
          final double width = MediaQuery.of(context).size.width;
          height = width / 2560 * 1600 + 32;
          y = widget.animation.value * -(width / 2560 * 1600 + 32) / 2;
        }
        return Transform.translate(
          offset: Offset(0, y),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: child,
            ),
          ),
        );
      },
      child: ValueListenableBuilder<double>(
        valueListenable: widget.offsetNotifier,
        builder: (context, value, child) {
          final double width = MediaQuery.of(context).size.width;
          double imageOffset = (value / width - widget.index).clamp(-1, 1) / 2;
          bool clipping = true;
          double scale = 1;
          Alignment alignment = Alignment.centerLeft;
          if (widget.index == 0 && imageOffset < 0) {
            clipping = false;
            scale -= imageOffset;
          } else if (widget.last && imageOffset > 0) {
            clipping = false;
            alignment = Alignment.centerRight;
            scale += imageOffset;
          }
          return Material(
            type: MaterialType.transparency,
            clipBehavior: clipping ? Clip.hardEdge : Clip.none,
            child: Transform.translate(
              offset: Offset(imageOffset * width * (clipping ? 1 : 2), 0),
              child: Transform.scale(
                scale: scale,
                alignment: alignment,
                child: child,
              ),
            ),
          );
        },
        child: OverflowBox(
          minWidth: MediaQuery.of(context).size.width,
          maxWidth: double.infinity,
          child: GestureDetector(
            // For debugging only, disable on release
            onLongPress: () {
              getApplicationDocumentsDirectory().then((dir) {
                File file = File(
                    '${dir.path}/stalls-${widget.stallName.toLowerCase()}-image.png');
                file.exists().then((exists) {
                  if (exists) {
                    print('Image Deleted!');
                    file.delete();
                  }
                });
              });
            },
            child: _imageProvider == null
                ? SizedBox()
                : FadeInImage(
                    fadeInDuration: Duration(milliseconds: 400),
                    placeholder: MemoryImage(kTransparentImage),
                    image: _imageProvider,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FoodItem extends StatefulWidget {
  FoodItem({Key key}) : super(key: key);
  _FoodItemState createState() => _FoodItemState();
}

class _FoodItemState extends State<FoodItem> {
  double shadow = 0.0;
  File imageFile;
  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((dir) {
      File file = File('${dir.path}/food.jpg');
      file.exists().then((exists) {
        if (exists)
          setState(() => imageFile = file);
        else {
          FirebaseStorage.instance
              .ref()
              .child('food.jpg')
              .getData(10 * 1024 * 1024)
              .then((data) {
            file.writeAsBytes(data).then((file) {
              setState(() {
                imageFile = file;
              });
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 8.0 * 3) / 2;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 6.0,
      ),
      child: Column(
        children: <Widget>[
          Material(
            elevation: shadow,
            shadowColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.yellowAccent
                : Colors.black,
            borderRadius: BorderRadius.circular(12.0),
            clipBehavior: Clip.antiAlias,
            child: AnimatedOpacity(
              opacity: imageFile != null ? 1.0 : 0.0,
              duration: Duration(
                milliseconds: 500,
              ),
              child: imageFile != null
                  ? Ink.image(
                      width: cardWidth,
                      height: cardWidth,
                      fit: BoxFit.cover,
                      image: FileImage(imageFile),
                      child: InkWell(
                        onTap: () {
                          print('Yay');
                          setState(() => shadow = 0.0);
                        },
                        onTapDown: (_) {
                          setState(() => shadow = 12.0);
                        },
                        onTapCancel: () {
                          setState(() => shadow = 0.0);
                        },
                      ),
                    )
                  : SizedBox(
                      width: cardWidth,
                      height: cardWidth,
                    ),
            ),
          ),
          SizedBox(
            height: 6.0,
          ),
          Text('Food'),
          Text(
            '\$3.00',
            style: Theme.of(context).textTheme.subtitle,
          ),
        ],
      ),
    );
  }
}
