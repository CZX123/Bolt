import 'library.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

String userID;
String name;
String email;
String imageUrl;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAE800),
              Color(0xFFF9B300),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image(
                  image: AssetImage('assets/icons/png/icon-white.png'),
                  height: 160.0),
              SizedBox(height: 120),
              _signInButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signInButton() {
    return RaisedButton(
      color: Colors.white,
      splashColor: Colors.white,
      onPressed: () async {
        signInWithGoogle();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(38.0)),
      highlightElevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage('assets/google-logo.png'), height: 30.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFF9B300),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void signInWithGoogle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    // Checking if email and name is null
    //assert(user.email != null);
    //assert(user.displayName != null);
    //assert(user.photoUrl != null);

    name = user.displayName;
    email = user.email;
    imageUrl = user.photoUrl;

    // Only taking the first part of the name, i.e., First Name
    /*
    if (name.contains(" ")) {
      name = name.substring(0, name.indexOf(" "));
    }
    */

    prefs.setString('name', name);
    prefs.setString('email', email);
    prefs.setString('imageUrl', imageUrl);

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    if (user != null) {
      prefs.setBool('success', true);
      userID = user.uid;
    } else {
      prefs.setBool('success', false);
    }

    bool _success = prefs.getBool('success');

    if (_success == true) {
      /*
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return Home();
          },
        ),
      );
      */
      Navigator.pushReplacementNamed(context, '/2');
    } else {
      Navigator.pushReplacementNamed(context, '/1');
    }
  }
}
