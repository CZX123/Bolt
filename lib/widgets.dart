import 'package:flutter/material.dart';

class Card extends StatelessWidget {
  Card({this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      elevation: 12.0,
      child: child,
    );
  }
}
