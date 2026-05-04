import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handles all Firebase Authentication logic for FocusNFlow.
// Sign up, sign in, and sign out all live here so the screens
// don't talk to Firebase directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Exposes the currently signed-in user, or null if no one is logged in.
  User? get currentUser => _auth.currentUser;

  // Real-time stream of auth changes — main.dart listens to this to decide
  // which screen to show.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password, String name) async {
    // Only allow GSU student emails — enforced before anything hits Firebase.
    if (!email.endsWith('@student.gsu.edu')) {
      return 'Only @student.gsu.edu emails are allowed';
    }

    UserCredential? result;
    try {
      // Create the Firebase Auth account first.
      result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store the display name in the auth profile so it shows everywhere.
      await result.user!.updateDisplayName(name);

      // Create the user's Firestore profile document under users/{uid}.
      // If this write fails (e.g. no internet), we delete the auth account
      // so we don't end up with an auth user that has no Firestore doc.
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'displayName': name,
        'email': email,
        'courses': [],       // courses the student is enrolled in
        'photoURL': '',      // filled in later when they upload a profile photo
        'fcmToken': '',      // filled in by FCMService after login
        'notificationsEnabled': true,
        'groupAlertsEnabled': true,
        'createdAt': Timestamp.now(),
      });

      return null; // null = no error, signup succeeded
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    } catch (_) {
      // Firestore write failed — roll back the auth account so nothing is orphaned.
      await result?.user?.delete().catchError((_) {});
      return 'Could not finish signup — please try again.';
    }
  }

  Future<String?> signIn(String email, String password) async {
    // Same GSU check on sign in — even if someone somehow has an account,
    // we validate the domain here too.
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

  // Converts Firebase error codes into readable messages for the user.
  // Raw codes like "wrong-password" are not user-friendly.
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
