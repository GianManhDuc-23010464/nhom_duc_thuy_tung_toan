import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user.dart';

class AuthService {
  AuthService({firebase_auth.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? lastErrorCode;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> register(String username, String email, String password) async {
    lastErrorCode = null;
    firebase_auth.UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(username.trim());

      final now = DateTime.now();
      final user = User(
        id: firebaseUser.uid,
        username: username.trim(),
        email: firebaseUser.email ?? email.trim().toLowerCase(),
        createdAt: now,
      );

      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(firebaseUser.uid),
        user.toFirestore(),
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .collection('stats')
            .doc('summary'),
        {
          'streak': 0,
          'todayStudied': 0,
          'todayDate': '',
          'lastStudyDate': '',
          'totalTests': 0,
          'totalMastered': 0,
          'updatedAt': Timestamp.fromDate(now),
        },
      );
      await batch.commit();

      await _auth.signOut();
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      lastErrorCode = error.code;
      return false;
    } on FirebaseException catch (error) {
      lastErrorCode = 'profile-${error.code}';
      await _deleteIncompleteRegistration(credential);
      return false;
    } catch (_) {
      lastErrorCode = 'profile-write-failed';
      await _deleteIncompleteRegistration(credential);
      return false;
    }
  }

  Future<void> _deleteIncompleteRegistration(
    firebase_auth.UserCredential? credential,
  ) async {
    if (credential?.user != null) {
      try {
        await credential!.user!.delete();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<bool> login(String email, String password) async {
    lastErrorCode = null;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      lastErrorCode = error.code;
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    lastErrorCode = null;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      lastErrorCode = error.code;
      return false;
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return User.fromFirestore(firebaseUser.uid, snapshot.data()!);
    }

    return User(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ?? 'Người dùng',
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<bool> isLoggedIn() async => _auth.currentUser != null;

  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;
}
