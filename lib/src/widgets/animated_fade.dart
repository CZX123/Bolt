import 'package:flutter/widgets.dart';

class AnimatedFade extends ImplicitlyAnimatedWidget {
  final double opacity;
  final Widget child;

  AnimatedFade({
    @required this.opacity,
    @required this.child,
    Duration duration: const Duration(milliseconds: 200),
    Curve curve: Curves.ease,
    Key key,
  }) : super(duration: duration, curve: curve, key: key);
  @override
  _AnimatedFadeState createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends AnimatedWidgetBaseState<AnimatedFade> {
  Tween<double> _opacityTween;

  @override
  void forEachTween(visitor) {
    _opacityTween = visitor(
        _opacityTween, widget.opacity, (value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityTween.animate(animation),
      child: widget.child,
    );
  }
}
