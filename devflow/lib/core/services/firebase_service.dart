import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for Firebase Authentication instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Riverpod provider for Cloud Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Service for initializing Firebase multiplatform
class FirebaseService {
  static Future<void> initialize({FirebaseOptions? options}) async {
    await Firebase.initializeApp(
      options: options,
    );
  }
}
