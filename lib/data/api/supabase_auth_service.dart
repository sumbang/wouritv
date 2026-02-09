import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;

/// Service d'authentification pour Supabase
class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Inscription avec email et mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      developer.log('🔐 Démarrage OAuth Google', name: 'SupabaseAuthService');
      
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.wouritv://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      developer.log('✅ signInWithOAuth retourné: $response', name: 'SupabaseAuthService');
      return response;
    } catch (e) {
      developer.log('❌ Exception OAuth Google: $e', name: 'SupabaseAuthService');
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Connexion avec Apple
  Future<bool> signInWithApple() async {
    try {
      developer.log('🔐 Démarrage OAuth Apple', name: 'SupabaseAuthService');
      
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.wouritv://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      developer.log('✅ signInWithOAuth retourné: $response', name: 'SupabaseAuthService');
      return response;
    } catch (e) {
      developer.log('❌ Exception OAuth Apple: $e', name: 'SupabaseAuthService');
      throw Exception('Erreur lors de la connexion Apple: $e');
    }
  }

  /// Connexion avec Facebook
  Future<bool> signInWithFacebook() async {
    try {
      developer.log('🔐 Démarrage OAuth Facebook', name: 'SupabaseAuthService');
      developer.log('🔐 redirectTo utilisé: ${kIsWeb ? "null (web)" : "io.supabase.wouritv://login-callback/ (mobile)"}', name: 'SupabaseAuthService');
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        // Ne pas spécifier redirectTo sur mobile - utilise le deep link configuré
        redirectTo: kIsWeb ? null : 'io.supabase.wouritv://login-callback/',
      );
      
      developer.log('✅ signInWithOAuth retourné: $response', name: 'SupabaseAuthService');
      return response;
    } catch (e) {
      developer.log('❌ Exception OAuth Facebook: $e', name: 'SupabaseAuthService');
      throw Exception('Erreur lors de la connexion Facebook: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      developer.log('🚪 Début de la déconnexion', name: 'SupabaseAuthService');
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      developer.log('👤 Utilisateur actuel: ${currentUser?.id} (${currentUser?.email})', name: 'SupabaseAuthService');
      
      await Supabase.instance.client.auth.signOut();
      
      developer.log('✅ Appel signOut() terminé', name: 'SupabaseAuthService');
      
      final userAfterSignOut = Supabase.instance.client.auth.currentUser;
      developer.log('👤 Utilisateur après déconnexion: ${userAfterSignOut?.id ?? "null"}', name: 'SupabaseAuthService');
      
      if (userAfterSignOut != null) {
        developer.log('⚠️ ATTENTION: L\'utilisateur est toujours connecté après signOut!', name: 'SupabaseAuthService');
      } else {
        developer.log('✅ Déconnexion réussie - utilisateur null', name: 'SupabaseAuthService');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Erreur lors de la déconnexion',
        error: e,
        stackTrace: stackTrace,
        name: 'SupabaseAuthService',
      );
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation du mot de passe: $e');
    }
  }

  /// Mise à jour du mot de passe
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  /// Mise à jour des données utilisateur
  Future<UserResponse> updateUserMetadata({
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: metadata),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Récupérer l'utilisateur actuel
  User? get currentUser => _client.auth.currentUser;

  /// Récupérer la session actuelle
  Session? get currentSession => _client.auth.currentSession;

  /// Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Stream pour écouter les changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Récupérer le token d'accès
  Future<String?> getAccessToken() async {
    final session = currentSession;
    return session?.accessToken;
  }

  /// Rafraîchir la session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      return response;
    } catch (e) {
      throw Exception('Erreur lors du rafraîchissement de la session: $e');
    }
  }

  /// Vérifier l'email avec OTP
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la vérification OTP: $e');
    }
  }

  /// Connexion avec lien magique (magic link)
  Future<void> signInWithMagicLink({required String email}) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.wouritv://login-callback/',
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du lien magique: $e');
    }
  }
}
