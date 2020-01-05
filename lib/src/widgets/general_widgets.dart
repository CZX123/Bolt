import '../../library.dart';

// Insert commonly used widgets here
class Footer extends StatelessWidget {
  final List<FooterButton> buttons;
  const Footer({Key key, @required this.buttons})
      : assert(buttons != null),
        assert(buttons.length != 0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.windowPadding.bottom;
    return Container(
      height: 80 + bottomPadding,
      padding: EdgeInsets.fromLTRB(24, 16, 0, 16 + bottomPadding),
      child: Row(
        children: <Widget>[
          for (FooterButton button in buttons)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: RaisedButton(
                  elevation: 0,
                  highlightElevation: 6,
                  color: button.color ?? context.theme.cardColor,
                  colorBrightness: button.colorBrightness,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (button.icon != null) button.icon,
                      const SizedBox(width: 6),
                      if (button.text != null) Text(button.text),
                      SizedBox(width: button.icon != null ? 8 : 6),
                    ],
                  ),
                  onPressed: button.onTap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FooterButton {
  final Icon icon;
  final String text;
  final Color color;
  final Brightness colorBrightness;
  final VoidCallback onTap;
  const FooterButton({
    this.icon,
    this.text,
    this.color,
    this.colorBrightness,
    this.onTap,
  })
  // Either icon or text needs to be present
  : assert(icon != null || text != null);
}
