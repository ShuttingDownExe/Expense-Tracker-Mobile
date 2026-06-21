import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Authentication. The app authenticates against the same
/// Firebase project the API verifies tokens for (expense-tracker-a9ebd), so
/// the ID token issued here is accepted by the backend's Admin SDK.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Web OAuth client id (client_type 3 in google-services.json). Used as the
  /// serverClientId so the ID token Google issues has the right audience for
  /// Firebase to accept it.
  static const _googleServerClientId =
      '202069546642-fq8jn02ejttqgtocsmv2eq5om8dc2puk.apps.googleusercontent.com';

  bool _googleReady = false;

  /// Emits the current user (or null) whenever auth state changes.
  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Returns a fresh Firebase ID token for the signed-in user, or null if
  /// signed out. Passed to [ApiService] as its token provider.
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  /// Sign in with Google using the native account picker (Google Play
  /// Services), then exchange the Google ID token for a Firebase session.
  /// Requires the app's SHA-1 to be registered on the Firebase Android app.
  Future<UserCredential> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: _googleServerClientId);
      _googleReady = true;
    }

    final account = await google.authenticate(scopeHint: const ['email']);
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  /// Maps Firebase / Google sign-in errors to human-readable messages.
  static String describeError(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Sign-in cancelled.';
      }
      return error.description ?? 'Google sign-in failed.';
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'web-context-canceled':
        case 'canceled':
          return 'Sign-in cancelled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    return 'Authentication failed.';
  }
}
