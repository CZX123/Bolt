import '../library.dart';

class AccountPage extends StatefulWidget {
  final Function(bool) changeScreen;
  final bool isCurrentOrders;
  const AccountPage({
    Key key,
    @required this.changeScreen,
    @required this.isCurrentOrders,
  }) : super(key: key);
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void _showSignOutDialog() {
    showCustomDialog(
      context: context,
      dialog: AlertDialog(
        backgroundColor: context.theme.canvasColor,
        title: Text('Sign Out'),
        content: Text(
          'Are you sure you want to sign out?',
          style: context.theme.textTheme.body1,
        ),
        actions: <Widget>[
          FlatButton(
            color: context.theme.cardColor,
            highlightColor:
                context.theme.colorScheme.onSurface.withOpacity(.12),
            splashColor: context.theme.colorScheme.onSurface.withOpacity(.12),
            child: Text(
              'No',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          FlatButton(
            color: context.theme.accentColor,
            highlightColor: Colors.white12,
            splashColor: Colors.white12,
            child: Text(
              'Yes',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              LoginApi.signOut(context);
            },
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.get<UserData>();
    final themeModel = context.get<ThemeModel>();
    final user = context.get<User>().value;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: context.windowSize.height,
        ),
        child: Padding(
          padding: context.windowPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (user != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: context.theme.hintColor,
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl)
                                : null,
                            child: user.photoUrl == null ? Center(
                              child: Text(
                                user.displayName[0],
                                style: TextStyle(
                                  fontSize: 32,
                                  color: context.theme.canvasColor,
                                ),
                              ),
                            ) : null,
                          ),
                          const SizedBox(
                            height: 16,
                            width: double.infinity,
                          ),
                          Text(
                            user.displayName,
                            style: context.theme.textTheme.body2,
                          ),
                          Text(
                            user.email,
                            style: context.theme.textTheme.caption,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Balance',
                            style: context.theme.textTheme.subtitle,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          CustomAnimatedSwitcher(
                            child: Text(
                              '\$${userData.balance.toStringAsFixed(2)}',
                              key: ValueKey(userData.balance),
                              style: context.theme.textTheme.display1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.home,
                        color: context.theme.hintColor,
                      ),
                      title: Text('Stalls'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.changeScreen(false);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.restaurant,
                        color: context.theme.hintColor,
                      ),
                      title: Text('Current Orders'),
                      trailing: userData.hasOrders
                          ? Container(
                              decoration: BoxDecoration(
                                color: context.theme.accentColor,
                                shape: BoxShape.circle,
                              ),
                              height: 8,
                              width: 8,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.changeScreen(true);
                      },
                    ),
                  ],
                )
              else
                SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      color: Theme.of(context).hintColor,
                      icon: Icon(Icons.exit_to_app),
                      tooltip: 'Sign Out',
                      onPressed: _showSignOutDialog,
                    ),
                    IconButton(
                      color: Theme.of(context).hintColor,
                      icon: CustomAnimatedSwitcher(
                        child: Icon(
                          themeModel.isDark
                              ? Icons.brightness_2
                              : Icons.brightness_6,
                          key: ValueKey(themeModel.isDark),
                        ),
                      ),
                      tooltip: 'Change Theme',
                      onPressed: () {
                        themeModel.isDark = !themeModel.isDark;
                      },
                    ),
                  ],
                ),
              ),
              // ListTile(
              //   title: Text(
              //     'Theme',
              //     style: context.theme.textTheme.display1,
              //   ),
              // ),
              // SwitchListTile(
              //   title: Text('Dark Mode'),
              //   value: themeModel.isDark,
              //   onChanged: (value) {
              //     themeModel.isDark = value;
              //   },
              // ),
              // Divider(),
              // ListTile(
              //   title: Text(
              //     'Other Settings',
              //     style: context.theme.textTheme.display1,
              //   ),
              // ),
              // ListTile(
              //   title: Text('Sign Out'),
              //   onTap: _showSignOutDialog,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
