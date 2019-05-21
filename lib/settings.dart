import 'package:flutter/material.dart';
import 'main.dart';

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
        SwitchListTile(
          title: Text('Dark Mode'),
          subtitle: Text('Come join the dark side'),
          value: BoltApp.of(context).isDarkTheme,
          onChanged: (toggle) {
            BoltApp.of(context).darkTheme(toggle);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: Text('True Black'),
          subtitle: Text('For your OLED screens'),
          value: BoltApp.of(context).blackOverDark,
          onChanged: BoltApp.of(context).isDarkTheme
              ? (toggle) {
                  BoltApp.of(context).blackTheme(toggle);
                  setState(() {});
                }
              : null,
        ),
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
