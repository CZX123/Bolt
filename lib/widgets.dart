import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
          print('Downloading Image');
          FirebaseStorage.instance
              .ref()
              .child('food.jpg')
              .getData(10 * 1024 * 1024)
              .then((data) {
            file.writeAsBytes(data).then((file) {
              print('Done');
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
    double cardWidth = (screenWidth - 4.0 * 2) / 2;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 6.0,
      ),
      width: cardWidth,
      child: Column(
        children: <Widget>[
          Material(
            elevation: shadow,
            shadowColor: Theme.of(context).brightness == Brightness.dark ? Colors.yellowAccent : Colors.black,
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
            'Other Info',
            style: Theme.of(context).textTheme.subtitle,
          ),
        ],
      ),
    );
  }
}
