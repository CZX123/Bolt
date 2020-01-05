import '../../library.dart';

Future<T> showCustomDialog<T>({
  @required BuildContext context,
  @required Widget dialog,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'Dismiss',
    barrierDismissible: barrierDismissible,
    transitionDuration: 200.milliseconds,
    barrierColor: Colors.black.withOpacity(0.5),
    useRootNavigator: false,
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Interval(0, 0.5),
        ),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: .7,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.fastLinearToSlowEaseIn,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return dialog;
    },
  );
}
