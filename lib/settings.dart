import 'package:flutter/material.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void changeTheme(int newThemeCode) {
    AppTheme.of(context).changeTheme(newThemeCode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int _themeCode = AppTheme.of(context).themeCode;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(72.0, 20.0, 72.0, 8.0),
            child: Text(
              'CHANGE THEME',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 15.0,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          RadioListTile<int>(
            title: Text('Light Theme'),
            value: 0,
            groupValue: _themeCode,
            onChanged: changeTheme,
          ),
          RadioListTile<int>(
            title: Text('Dark Theme'),
            value: 1,
            groupValue: _themeCode,
            onChanged: changeTheme,
          ),
          RadioListTile<int>(
            title: Text('Black Theme'),
            value: 2,
            groupValue: _themeCode,
            onChanged: changeTheme,
          ),
        ],
      ),
    );
  }
}
