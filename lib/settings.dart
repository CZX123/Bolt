import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

class SettingsWidget extends StatefulWidget {
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  bool randomToggle = false;
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          title: Text(
            'Theme',
            style: Theme.of(context).textTheme.display1,
          ),
        ),
        ThemeOptions(),
        Divider(),
        ListTile(
          title: Text(
            'Other Settings',
            style: Theme.of(context).textTheme.display1,
          ),
        ),
        SwitchListTile(
          title: Text('Random Toggle'),
          value: randomToggle,
          onChanged: (toggle) {
            setState(() {
              randomToggle = toggle;
            });
          },
        ),
      ],
    );
  }
}

class ThemeOptions extends StatelessWidget {
  const ThemeOptions();

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = Provider.of<ThemeState>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlineButton(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                borderSide: BorderSide(
                  width: 1.2,
                  color: themeState.themeCode == 0
                      ? Colors.amber[700]
                      : Theme.of(context).dividerColor,
                ),
                color: themeList[0].canvasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => themeState.setThemeCode(0),
                child: Center(
                  child: Text(
                    'LIGHT',
                    style: Theme.of(context).textTheme.body2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlineButton(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                borderSide: BorderSide(
                  width: 1.2,
                  color: themeState.themeCode == 1
                      ? Colors.yellowAccent
                      : Theme.of(context).dividerColor,
                ),
                color: themeList[1].canvasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => themeState.setThemeCode(1),
                child: Center(
                  child: Text(
                    'DARK',
                    style: Theme.of(context).textTheme.body2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlineButton(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                borderSide: BorderSide(
                  width: 1.2,
                  color: themeState.themeCode == 2
                      ? Colors.yellowAccent
                      : Theme.of(context).dividerColor,
                ),
                color: themeList[2].canvasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () => themeState.setThemeCode(2),
                child: Center(
                  child: Text(
                    'BLACK',
                    style: Theme.of(context).textTheme.body2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
