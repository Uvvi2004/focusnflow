import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp(String email, String password, String name) async {
    try {
      if (!email.endsWith('@student.gsu.edu')) {
        return 'Only @student.gsu.edu emails are allowed';
      }
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save display name to Firebase Auth profile
      await result.user!.updateDisplayName(name);
      // Save user profile to Firestore
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'displayName': name,
        'email': email,
        'courses': [],
        'photoURL': '',
        'fcmToken': '',
        'createdAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}