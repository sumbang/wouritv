import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour gérer l'accès aux vidéos premium
class PremiumVideoService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _listeTableName = 'liste';
  
  // ANON_KEY hardcodé pour appels directs aux Edge Functions
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmcGt4cWZxbGh6ZnZ3cG1lanZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcwMjUzNDYsImV4cCI6MjA2MjYwMTM0Nn0.cSdTBhGg81eY_YN_2zMfWB8T4b7gPqiIr4_Szu79cYw';
  
  // Secret partagé pour authentifier les appels à l'Edge Function
  static const String _functionSecret = 'wouri-cloudfront-secret-2026';

  /// Vérifier si l'utilisateur a acheté un film
  Future<bool> hasUserPurchased({
    required String movieId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from(_listeTableName)
          .select('achat, expirationDate')
          .eq('userId', userId)
          .eq('movieId', movieId)
          .eq('achat', true)
          .maybeSingle();
      
      if (response == null) return false;
      
      // Vérifier si l'achat n'a pas expiré
      final expirationDate = response['expirationDate'] as String?;
      if (expirationDate != null) {
        final expiration = DateTime.parse(expirationDate);
        if (DateTime.now().isAfter(expiration)) {
          developer.log('⚠️ Achat expiré pour le film: $movieId', name: 'PremiumVideoService');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      developer.log('❌ Erreur vérification achat: $e', name: 'PremiumVideoService');
      return false;
    }
  }

  /// Enregistrer un achat (appelé après paiement réussi)
  Future<void> recordPurchase({
    required String movieId,
    required String userId,
    DateTime? expirationDate,
  }) async {
    try {
      // Vérifier si l'entrée existe déjà
      final existing = await _client
          .from(_listeTableName)
          .select('id')
          .eq('userId', userId)
          .eq('movieId', movieId)
          .maybeSingle();
      
      if (existing != null) {
        // Mettre à jour l'entrée existante
        await _client.from(_listeTableName).update({
          'achat': true,
          'expirationDate': expirationDate?.toIso8601String(),
          'operationDate': DateTime.now().toIso8601String(),
        }).eq('userId', userId).eq('movieId', movieId);
      } else {
        // Créer une nouvelle entrée
        await _client.from(_listeTableName).insert({
          'userId': userId,
          'movieId': movieId,
          'achat': true,
          'expirationDate': expirationDate?.toIso8601String(),
          'operationDate': DateTime.now().toIso8601String(),
        });
      }
      
      developer.log('✅ Achat enregistré: $movieId', name: 'PremiumVideoService');
    } catch (e) {
      developer.log('❌ Erreur enregistrement achat: $e', name: 'PremiumVideoService');
      rethrow;
    }
  }

  /// Récupérer l'URL signée CloudFront pour un contenu premium S3
  /// 
  /// [s3Path] : Chemin du fichier dans S3 (ex: "premium/film-1.mp4")
  /// [movieId] : ID du film pour vérification d'achat
  Future<String?> getSignedUrl({
    required String movieId,
    required String s3Path,
  }) async {
    try {
      developer.log('🔐 Demande URL signée pour S3: $s3Path (film: $movieId)', name: 'PremiumVideoService');
      
      // Vérifier l'utilisateur
      final userId = _client.auth.currentUser?.id;
      final session = _client.auth.currentSession;
      
      if (userId == null || session == null) {
        developer.log('❌ Aucun utilisateur connecté', name: 'PremiumVideoService');
        return null;
      }
      
      developer.log('✅ User ID: $userId', name: 'PremiumVideoService');
      developer.log('🔑 Utilisation secret: ${_functionSecret.substring(0, 10)}...', name: 'PremiumVideoService');
      
      // Utiliser http.post directement car functions.invoke() ignore les headers customs
      final url = Uri.parse('https://efpkxqfqlhzfvwpmejfp.supabase.co/functions/v1/generate-signed-url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'x-function-secret': _functionSecret,
        },
        body: jsonEncode({
          'userId': userId,
          'movieId': movieId,
          's3Path': s3Path,
        }),
      );
      
      developer.log('📡 Response status: ${response.statusCode}', name: 'PremiumVideoService');
      developer.log('📄 Response body: ${response.body}', name: 'PremiumVideoService');
      
      if (response.statusCode != 200) {
        developer.log('❌ Erreur serveur: ${response.statusCode} - ${response.body}', name: 'PremiumVideoService');
        return null;
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data.containsKey('error')) {
        developer.log('❌ Erreur: ${data['error']}', name: 'PremiumVideoService');
        return null;
      }
      
      final signedUrl = data['signedUrl'] as String;
      developer.log('✅ URL signée CloudFront reçue', name: 'PremiumVideoService');
      
      return signedUrl;
    } catch (e) {
      developer.log('❌ Erreur récupération URL signée: $e', name: 'PremiumVideoService');
      return null;
    }
  }
}
