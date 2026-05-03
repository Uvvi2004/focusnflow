import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password, String name) async {
    if (!email.endsWith('@student.gsu.edu')) {
      return 'Only @student.gsu.edu emails are allowed';
    }
    UserCredential? result;
    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user!.updateDisplayName(name);

      // Create the Firestore profile. If this throws (e.g. network loss),
      // roll back the auth account so we don't leave an orphan with no doc.
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'displayName': name,
        'email': email,
        'courses': [],
        'photoURL': '',
        'fcmToken': '',
        'notificationsEnabled': true,
        'groupAlertsEnabled': true,
        'pomodoroDuration': 25,
        'createdAt': Timestamp.now(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      await result?.user?.delete().catchError((_) {});
      return 'Could not finish signup — please try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (!email.endsWith('@student.gsu.edu')) {
      return 'Only @student.gsu.edu emails are allowed';
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      return 'Could not sign in — check your connection.';
    }
  }

  Future<void> signOut() async => _auth.signOut();

  // Map Firebase error codes to short, user-facing strings.
  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error — check your connection.';
      default:
        return 'Error: $code';
    }
  }
}
