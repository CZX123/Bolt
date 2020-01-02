import 'library.dart';

class SettingsPage extends StatefulWidget {
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool randomToggle = false;

  void _showSignOutDialog() {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Sign Out"),
          content: Text("Are you sure you want to sign out?"),
          actions: <Widget>[
            FlatButton(
              child: Text("No"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text("Yes"),
              onPressed: () {
                LoginApi.signOut(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeModel themeModel = Provider.of<ThemeModel>(context);
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
            value: themeModel.isDark,
            onChanged: (value) {
              themeModel.isDark = value;
            },
          ),
          Divider(),
          ListTile(
            title: Text(
              'Other Settings',
              style: Theme.of(context).textTheme.display1,
            ),
          ),
          ListTile(
            title: Text('Sign Out'),
            onTap: _showSignOutDialog,
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
