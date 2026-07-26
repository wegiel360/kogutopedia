import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthNotifier(this._auth) : super(const AuthState()) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    state = state.copyWith(user: user, error: null);
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Nie znaleziono użytkownika';
          break;
        case 'wrong-password':
          msg = 'Nieprawidłowe hasło';
          break;
        case 'invalid-email':
          msg = 'Nieprawidłowy email';
          break;
        case 'invalid-credential':
          msg = 'Nieprawidłowe dane logowania';
          break;
        default:
          msg = e.message ?? 'Błąd logowania';
      }
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'weak-password':
          msg = 'Hasło jest za słabe (minimum 6 znaków)';
          break;
        case 'email-already-in-use':
          msg = 'Email jest już zajęty';
          break;
        case 'invalid-email':
          msg = 'Nieprawidłowy email';
          break;
        default:
          msg = e.message ?? 'Błąd rejestracji';
      }
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Błąd wysyłania resetu hasła',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(FirebaseAuth.instance);
});
