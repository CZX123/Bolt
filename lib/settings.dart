import 'library.dart';

class SettingsPage extends StatefulWidget {
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool randomToggle = false;

  @override
  Widget build(BuildContext context) {
    ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: windowPadding.top,
          ),
          ListTile(
            title: Text(
              'Theme',
              style: Theme.of(context).textTheme.display1,
            ),
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            value: themeNotifier.isDark,
            onChanged: (value) {
              themeNotifier.isDark = value;
            },
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
      ),
    );
  }
}
