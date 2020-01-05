import 'library.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(24) + context.windowPadding,
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
      highlightColor: Colors.black12,
      splashColor: Colors.black12,
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
                color: Colors.black54,
                fontSize: 16,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class User extends ValueNotifier<FirebaseUser> {
  User(FirebaseUser value) : super(value);
}

class LoginApi {
  static final FirebaseAuth firebaseAuthentication = FirebaseAuth.instance;
  static final GoogleSignIn googleSignIn =
      GoogleSignIn(hostedDomain: "student.hci.edu.sg");
  static final HttpsCallable _addUserCallable =
      CloudFunctions.instance.getHttpsCallable(
    functionName: 'addUser',
  );

  static void _showError(BuildContext context) {
    showCustomDialog(
      context: context,
      dialog: AlertDialog(
        title: Text('Error'),
        content: Text('Could not sign in'),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Adds a user to firebase. Returns whether the operation was successful
  static Future<bool> _addUser() async {
    try {
      return (await _addUserCallable.call()).data['success'];
    } catch (e) {
      return false;
    }
  }

  static Future<void> signInWithGoogle(BuildContext context) async {
    GoogleSignInAccount googleSignInAccount;
    try {
      googleSignInAccount = await googleSignIn.signIn();
    } on PlatformException {
      _showError(context);
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
    final success = await _addUser();
    if (success) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);
      assert(user.uid == (await firebaseAuthentication.currentUser()).uid);
      context.get<User>().value = user;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      _showError(context);
    }
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await Future.wait([
        googleSignIn.signOut(),
        firebaseAuthentication.signOut(),
      ]);
      context.get<User>().value = null;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      return;
    }
  }
}
