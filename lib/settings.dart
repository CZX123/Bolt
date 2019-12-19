import 'library.dart';

class SettingsPage extends StatefulWidget {
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool randomToggle = false;

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
            title: Text(
              'Log Out'
            ),
            onTap: () {
              _showDialog();
            }
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

  void _showDialog() {
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        
        return AlertDialog(
          title: new Text("Log Out"),
          content: new Text("Are you sure?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("NO"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("YES"),
              onPressed: () {
                Navigator.of(context).pop();
                signOutGoogle();
              },
            ),
          ],
        );
      },
    );
  }


  void signOutGoogle() async {
    await googleSignIn.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('success', false);
    //success = false;
    print("User Sign Out");
    Navigator.pushReplacementNamed(context, '/1');           
  }
 
}
