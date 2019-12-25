import 'library.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final windowPadding = Provider.of<EdgeInsets>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAE800),
            Color(0xFFF9B300),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24) + windowPadding,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(),
            Image(
              image: AssetImage('assets/icons/png/icon-white.png'),
              height: 140,
            ),
            const LoginButton(),
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Colors.white,
      onPressed: () {
        LoginApi.signInWithGoogle(context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(69),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/google-logo.png'),
              height: 24,
            ),
            const SizedBox(width: 16),
            Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LoginApi {
  static final FirebaseAuth firebaseAuthentication = FirebaseAuth.instance;
  static final GoogleSignIn googleSignIn = GoogleSignIn();

  static void _updatePrefs(FirebaseUser user) async {
    final name = user.displayName;
    final email = user.email;
    final imageUrl = user.photoUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', name);
    prefs.setString('email', email);
    prefs.setString('imageUrl', imageUrl);
    prefs.setBool('success', true);
  }

  static Future<void> signInWithGoogle(BuildContext context) async {
    GoogleSignInAccount googleSignInAccount;
    try {
      googleSignInAccount = await googleSignIn.signIn();
    } on PlatformException {
      return;
    }
    final googleSignInAuthentication = await googleSignInAccount.authentication;
    final credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    final authResult = await firebaseAuthentication.signInWithCredential(
      credential,
    );
    final user = authResult.user;
    _updatePrefs(user);

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);
    assert(user.uid == (await firebaseAuthentication.currentUser()).uid);

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await googleSignIn.signOut();
    } on PlatformException {
      return;
    }
    SharedPreferences.getInstance().then((prefs) {
      return prefs.setBool('success', false);
    });

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
