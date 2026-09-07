import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Authentication provider
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user UID provider
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).value;
  return user?.uid;
});

/// Sign in with email/password
final signInProvider = FutureProvider.family<UserCredential, (String, String)>(
  (ref, credentials) async {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: credentials.$1,
      password: credentials.$2,
    );
  },
);

/// Sign up with email/password
final signUpProvider = FutureProvider.family<UserCredential, (String, String)>(
  (ref, credentials) async {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: credentials.$1,
      password: credentials.$2,
    );
  },
);

/// Sign out
final signOutProvider = FutureProvider<void>((ref) async {
  await FirebaseAuth.instance.signOut();
});
