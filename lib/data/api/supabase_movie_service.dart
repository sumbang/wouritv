import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wouritv/data/model/movie_content_model.dart';
import 'package:wouritv/data/model/movie_model.dart';
import 'package:wouritv/data/model/contenu_model.dart';
import 'package:wouritv/data/model/lecture_model.dart';
import 'package:hive/hive.dart';
import 'dart:developer' as developer;

/// Service pour interagir avec la table 'videos' de Supabase avec cache Hive
class SupabaseVideoService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'movie';
  static const String _recommendationTableName = 'recommendation';
  static const String _lectureTableName = 'lecture';
  static const String _contenuTableName = 'contenu';
  static const String _listeTableName = 'liste';
  
  // Durées de cache
  static const Duration _standardCacheDuration = Duration(hours: 3);
  static const Duration _shortCacheDuration = Duration(minutes: 5);
  static const Duration _movieDetailCacheDuration = Duration(minutes: 2);
  
  // Clés de cache
  static const String _cacheKeyLatest = 'latest_movies';
  static const String _cacheKeyRecommended = 'recommended_movies';
  static const String _cacheKeyMostWatched = 'most_watched_movies';
  static const String _cacheKeyRandom = 'random_movies';
  static const String _cacheKeySearch = 'search_movies_';
  static const String _cacheKeyCategory = 'category_movies_';
  static const String _cacheKeyChannel = 'channel_movies_';
  static const String _cacheKeyUserList = 'user_list_';
  static const String _cacheKeyMovieDetail = 'movie_detail_';

  /// Récupérer les 20 dernières vidéos avec cache
  Future<List<MovieModel>> fetchLatestMovies({int limit = 20}) async {
    final cacheKey = '${_cacheKeyLatest}_$limit';
    
    // Vérifier le cache
    final cachedData = await _getCachedMovies(cacheKey, _standardCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Données récupérées du cache pour: $cacheKey', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      developer.log('🔍 Début de fetchLatestMovies depuis Supabase', name: 'SupabaseVideoService');
      
      final response = await _client
          .from(_tableName)
          .select()
          .or('paiement.neq.OUI,prix.lte.0')
          .order('created_at', ascending: false)
          .limit(limit);

      final movies = (response as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
          
      // Mettre en cache
      await _cacheMovies(cacheKey, movies);
      developer.log('✅ ${movies.length} films transformés et mis en cache', name: 'SupabaseVideoService');
      
      return movies;
    } catch (e, stackTrace) {
      developer.log('❌ Erreur dans fetchLatestMovies', error: e, stackTrace: stackTrace, name: 'SupabaseVideoService');
      throw Exception('Erreur lors de la récupération des 20 dernières vidéos: $e');
    }
  }

  /// Récupérer les films les plus recommandés avec cache
  Future<List<MovieModel>> fetchMostRecommendedMovies({int limit = 20}) async {
    final cacheKey = '${_cacheKeyRecommended}_$limit';
    
    final cachedData = await _getCachedMovies(cacheKey, _standardCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Recommandations récupérées du cache', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      
      // Première requête : récupérer les films les plus recommandés
      final response = await _client
          .from(_recommendationTableName)
          .select('idmovie')
          .eq('recommand', true)
          .gte('operationDate', threeMonthsAgo.toIso8601String())
          .limit(limit * 2); // Prendre plus pour avoir de la marge

      if (response.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Compter les recommandations par film
      final movieCounts = <String, int>{};
      for (var item in response) {
        final movieIdValue = item['idmovie'];
        final movieId = movieIdValue?.toString(); // Convertir en String peu importe le type
        if (movieId != null) {
          movieCounts[movieId] = (movieCounts[movieId] ?? 0) + 1;
        }
      }

      // Trier par nombre de recommandations et prendre les IDs
      final movieEntries = movieCounts.entries.toList();
      movieEntries.sort((a, b) => b.value.compareTo(a.value));
      final sortedMovieIds = movieEntries
          .take(limit)
          .map((e) => e.key)
          .toList();

      if (sortedMovieIds.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Deuxième requête : récupérer les détails des films (exclure premium)
      final moviesResponse = await _client
          .from(_tableName)
          .select()
          .inFilter('id', sortedMovieIds)
          .or('paiement.neq.OUI,prix.lte.0');

      final movies = (moviesResponse as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      developer.log('✅ ${movies.length} films recommandés transformés', name: 'SupabaseVideoService');    

      if (movies.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Mélanger aléatoirement pour varier l'affichage
      movies.shuffle();

      await _cacheMovies(cacheKey, movies);
      return movies;
    } catch (e) {
      developer.log('❌ Erreur dans fetchMostRecommendedMovies: $e', name: 'SupabaseVideoService');
      return fetchRandomMovies(limit: limit);
    }
  }

  /// Récupérer les films les plus regardés avec cache
  Future<List<MovieModel>> mostWatchingMovie({int limit = 20}) async {
    final cacheKey = '${_cacheKeyMostWatched}_$limit';
    
    final cachedData = await _getCachedMovies(cacheKey, _standardCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Films les plus regardés récupérés du cache', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      // Première requête : récupérer toutes les lectures avec leurs durées
      final lectureResponse = await _client
          .from(_lectureTableName)
          .select('idmovie, duree')
          .limit(1000); // Limiter pour éviter trop de données

      if (lectureResponse.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Récupérer tous les contenus pour faire le lien idmovie -> movieId
      final contenuResponse = await _client
          .from(_contenuTableName)
          .select('videoId, movieId');

      // Créer un mapping videoId -> movieId
      final videoToMovieMap = <String, String>{};
      for (var contenu in contenuResponse) {
        final videoId = contenu['videoId']?.toString();
        final movieId = contenu['movieId']?.toString();
        if (videoId != null && movieId != null) {
          videoToMovieMap[videoId] = movieId;
        }
      }

      // Calculer le temps total de visionnage par film
      final movieWatchTime = <String, int>{};
      for (var lecture in lectureResponse) {
        final videoId = lecture['idmovie']?.toString();
        final duree = lecture['duree'] as int? ?? 0;
        
        if (videoId != null) {
          final movieId = videoToMovieMap[videoId];
          if (movieId != null) {
            movieWatchTime[movieId] = (movieWatchTime[movieId] ?? 0) + duree;
          }
        }
      }

      // Trier par temps de visionnage total et prendre les IDs
      final movieEntries = movieWatchTime.entries.toList();
      movieEntries.sort((a, b) => b.value.compareTo(a.value));
      final sortedMovieIds = movieEntries
          .take(limit)
          .map((e) => e.key)
          .toList();

      if (sortedMovieIds.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Dernière requête : récupérer les détails des films (exclure premium)
      final moviesResponse = await _client
          .from(_tableName)
          .select()
          .inFilter('id', sortedMovieIds)
          .or('paiement.neq.OUI,prix.lte.0');

      final movies = (moviesResponse as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      if (movies.isEmpty) {
        return fetchRandomMovies(limit: limit);
      }

      // Mélanger aléatoirement pour varier l'affichage
      movies.shuffle();

      await _cacheMovies(cacheKey, movies);
      return movies;
    } catch (e) {
      developer.log('❌ Erreur dans mostWatchingMovie: $e', name: 'SupabaseVideoService');
      return fetchRandomMovies(limit: limit);
    }
  }

  /// Récupérer des films aléatoires avec cache court
  Future<List<MovieModel>> fetchRandomMovies({int limit = 20}) async {
    final cacheKey = '${_cacheKeyRandom}_$limit';
    
    final cachedData = await _getCachedMovies(cacheKey, _shortCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Films aléatoires récupérés du cache', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      final response = await _client
          .from(_tableName)
          .select()          .or('paiement.neq.OUI,prix.lte.0')          .order('created_at', ascending: false)
          .limit(limit * 3);

      final allMovies = (response as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();

      allMovies.shuffle();
      final randomMovies = allMovies.take(limit).toList();
      
      await _cacheMovies(cacheKey, randomMovies);
      return randomMovies;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de films aléatoires: $e');
    }
  }

  /// Rechercher des vidéos avec cache court
  Future<List<MovieModel>> searchMovies(String query) async {
    final cacheKey = '$_cacheKeySearch${query.toLowerCase()}';
    
    final cachedData = await _getCachedMovies(cacheKey, _shortCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Résultats de recherche récupérés du cache', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      final response = await _client
          .from(_tableName)
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .or('paiement.neq.OUI,prix.lte.0')
          .order('created_at', ascending: false);

      final movies = (response as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
          
      await _cacheMovies(cacheKey, movies);
      return movies;
    } catch (e) {
      throw Exception('Erreur lors de la recherche de vidéos: $e');
    }
  }

  /// Récupérer les vidéos par catégorie avec cache
  Future<List<MovieModel>> fetchMoviesByCategory({required String category, required int page, int limit = 20}) async {
    final cacheKey = '$_cacheKeyCategory${category}_page${page}_limit$limit';
    
    final cachedData = await _getCachedMovies(cacheKey, _standardCacheDuration);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final offset = (page - 1) * limit;
      final response = await _client
          .from(_tableName)
          .select()
          .eq('categorie', category)
          .or('paiement.neq.OUI,prix.lte.0')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final movies = (response as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
          
      await _cacheMovies(cacheKey, movies);
      return movies;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des vidéos par catégorie: $e');
    }
  }

  /// Récupérer les vidéos par chaîne avec cache
  Future<List<MovieModel>> fetchMoviesByChannel({
    required int channel,
    required int page,
    int limit = 20,
  }) async {
    final cacheKey = '$_cacheKeyChannel${channel}_page${page}_limit$limit';
    
    final cachedData = await _getCachedMovies(cacheKey, _standardCacheDuration);
    if (cachedData != null) {
      return cachedData;
    }

    try {
      final offset = (page - 1) * limit;
      final response = await _client
          .from(_tableName)
          .select()
          .eq('chaineId', channel)
          .or('paiement.neq.OUI,prix.lte.0')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final movies = (response as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
          
      await _cacheMovies(cacheKey, movies);
      return movies;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des vidéos par chaîne: $e');
    }
  }

  /// Récupérer une vidéo par ID avec cache court (2 minutes)
  Future<MovieWithContentsResponse> fetchMovieById(String id, {String? userId}) async {
    final cacheKey = '$_cacheKeyMovieDetail${id}_${userId ?? "guest"}';
    
    // Vérifier le cache
    try {
      final box = await Hive.openBox('movie_cache');
      final cached = box.get(cacheKey);
      
      if (cached != null && cached is Map) {
        final timestamp = cached['timestamp'] as int?;
        final data = cached['data'];
        
        if (timestamp != null && data != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge < _movieDetailCacheDuration.inMilliseconds) {
            developer.log('✅ Détails du film récupérés du cache: $id', name: 'SupabaseVideoService');
            return MovieWithContentsResponse(
              movie: MovieModel.fromJson(Map<String, dynamic>.from(data['movie'])),
              contents: (data['contents'] as List)
                  .map((json) => ContenuModel.fromJson(Map<String, dynamic>.from(json)))
                  .toList(),
              isInList: data['isInList'] as bool,
              userRecommendation: data['userRecommendation'] as bool?,
            );
          }
        }
      }
    } catch (e) {
      developer.log('Erreur lors de la lecture du cache: $e', name: 'SupabaseVideoService');
    } 

    try {
      final movieResponse = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      final movie = MovieModel.fromJson(movieResponse);

      final contentsResponse = await _client
          .from(_contenuTableName)
          .select()
          .eq('movieId', id)
          .order('created_at', ascending: true);

      List<ContenuModel> contents = [];
      
      // Pour chaque contenu, récupérer les informations de lecture si l'utilisateur est connecté
      for (var contentJson in contentsResponse as List) {
        String? lastReading;
        String? lectureId;
        
        if (userId != null && contentJson['videoId'] != null) {
          developer.log(
            '🔍 Recherche lecture pour:\n'
            '   - videoId: ${contentJson['videoId']}\n'
            '   - userId: $userId',
            name: 'SupabaseVideoService'
          );
          
          // Récupérer la lecture la plus récente pour ce contenu
          final lectureResponse = await _client
              .from(_lectureTableName)
              .select('id, lastReading, duree')
              .eq('idmovie', contentJson['videoId'])
              .eq('iduser', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          
          developer.log('📦 Réponse lecture: $lectureResponse', name: 'SupabaseVideoService');
          
          if (lectureResponse != null) {
            // Le type 'time' de PostgreSQL doit être converti explicitement en String
            final rawLastReading = lectureResponse['lastReading'];
            
            developer.log(
              '🔍 Lecture trouvée:\n'
              '   - Type lastReading: ${rawLastReading.runtimeType}\n'
              '   - Valeur: $rawLastReading',
              name: 'SupabaseVideoService'
            );
            
            lastReading = rawLastReading?.toString();
            lectureId = lectureResponse['id']?.toString();
            developer.log('✅ Progression récupérée - ID: $lectureId, lastReading: $lastReading', name: 'SupabaseVideoService');
          } else {
            developer.log('❌ Aucune lecture trouvée pour ce contenu', name: 'SupabaseVideoService');
          }
        }
        
        // Ajouter les informations de lecture au JSON
        final enrichedJson = Map<String, dynamic>.from(contentJson);
        enrichedJson['lastReading'] = lastReading;
        enrichedJson['lectureId'] = lectureId;
        
        contents.add(ContenuModel.fromJson(enrichedJson));
      }

      // Vérifier si le film est dans la liste de l'utilisateur
      bool isInList = false;
      bool? userRecommendation;
      
      if (userId != null) {
        final listeResponse = await _client
            .from(_listeTableName)
            .select()
            .eq('movieId', id)
            .eq('userId', userId)
            .maybeSingle();
        isInList = listeResponse != null;
        
        // Vérifier la recommandation de l'utilisateur
        final recommendationResponse = await _client
            .from(_recommendationTableName)
            .select('recommand')
            .eq('idmovie', id)
            .eq('iduser', userId)
            .maybeSingle();
        
        if (recommendationResponse != null) {
          userRecommendation = recommendationResponse['recommand'] as bool?;
        }
      }

      final response = MovieWithContentsResponse(
        movie: movie,
        contents: contents,
        isInList: isInList,
        userRecommendation: userRecommendation,
      );
      
      // Mettre en cache après récupération réussie
      try {
        final box = await Hive.openBox('movie_cache');
        await box.put(cacheKey, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': {
            'movie': movie.toJson(),
            'contents': contents.map((c) => {
              'id': c.id,
              'title': c.title,
              'videoId': c.videoUrl,
              'movieId': c.movieId,
              'duree': c.duree,
              'created_at': c.createdAt?.toIso8601String(),
              'lastReading': c.lastReading,
              'lectureId': c.lectureId,
            }).toList(),
            'isInList': isInList,
            'userRecommendation': userRecommendation,
          },
        });
        developer.log('💾 Détails du film mis en cache: $id', name: 'SupabaseVideoService');
        developer.log('Temps de lecture: ${contents.isNotEmpty ? contents.first.lastReading : "N/A"}', name: 'SupabaseVideoService');
      } catch (e) {
        developer.log('Erreur lors de la mise en cache: $e', name: 'SupabaseVideoService');
      }
      
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la vidéo: $e');
    }
  }

  // Méthodes sans cache (opérations d'écriture)
  Future<void> recommandMovie({
    required String movieId,
    required String userId,
    required bool isRecommended,
  }) async {
    try {
      developer.log('👍 Recommandation - movieId: $movieId, userId: $userId, recommend: $isRecommended', name: 'SupabaseVideoService');
      
      // Vérifier si une recommandation existe déjà
      final existing = await _client
          .from(_recommendationTableName)
          .select()
          .eq('idmovie', movieId)
          .eq('iduser', userId)
          .maybeSingle();
      
      if (existing != null) {
        // Mettre à jour la recommandation existante
        await _client
            .from(_recommendationTableName)
            .update({
              'recommand': isRecommended,
              'operationDate': DateTime.now().toIso8601String(),
            })
            .eq('idmovie', movieId)
            .eq('iduser', userId);
        developer.log('✅ Recommandation mise à jour', name: 'SupabaseVideoService');
      } else {
        // Créer une nouvelle recommandation
        await _client.from(_recommendationTableName).insert({
          'idmovie': movieId,
          'iduser': userId,
          'recommand': isRecommended,
          'operationDate': DateTime.now().toIso8601String(),
        });
        developer.log('✅ Nouvelle recommandation créée', name: 'SupabaseVideoService');
      }
      
      // Invalider le cache des recommandations
      await _invalidateCache(_cacheKeyRecommended);
    } catch (e) {
      developer.log('❌ Erreur lors de la recommandation: $e', name: 'SupabaseVideoService');
      throw Exception('Erreur lors de la recommandation du film: $e');
    }
  }

  /// Récupérer la recommandation actuelle d'un utilisateur pour un film
  Future<bool?> getMovieRecommendation({
    required String movieId,
    required String userId,
  }) async {
    try {
      final result = await _client
          .from(_recommendationTableName)
          .select('recommand')
          .eq('idmovie', movieId)
          .eq('iduser', userId)
          .maybeSingle();
      
      if (result != null) {
        return result['recommand'] as bool?;
      }
      return null;
    } catch (e) {
      developer.log('❌ Erreur lors de la récupération de la recommandation: $e', name: 'SupabaseVideoService');
      return null;
    }
  }

  /// Supprimer la recommandation d'un utilisateur pour un film
  Future<void> removeMovieRecommendation({
    required String movieId,
    required String userId,
  }) async {
    try {
      await _client
          .from(_recommendationTableName)
          .delete()
          .eq('idmovie', movieId)
          .eq('iduser', userId);
      
      // Invalider le cache des recommandations
      await _invalidateCache(_cacheKeyRecommended);
      developer.log('✅ Recommandation supprimée', name: 'SupabaseVideoService');
    } catch (e) {
      developer.log('❌ Erreur lors de la suppression de la recommandation: $e', name: 'SupabaseVideoService');
      throw Exception('Erreur lors de la suppression de la recommandation: $e');
    }
  }


  Future<Map<String, dynamic>?> getCurrentWatching({required String movieId, required String userId}) async {
    try {
      final response = await _client
          .from(_lectureTableName)
          .select()
          .eq('idmovie', movieId)
          .eq('iduser', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la lecture en cours: $e');
    }
  }

  /// Ajouter un film à la liste de l'utilisateur
  Future<void> addMovieToList({
    required String movieId,
    required String userId,
  }) async {
    try {
      developer.log('➕ Ajout à la liste - movieId: $movieId, userId: $userId', name: 'SupabaseVideoService');
      
      await _client.from(_listeTableName).insert({
        'movieId': movieId,
        'userId': userId,
        'achat': false,
        'expirationDate': null,
      });
      
      // Invalider le cache de la liste utilisateur
      await _invalidateCache('$_cacheKeyUserList$userId');
      
      developer.log('✅ Film ajouté avec succès', name: 'SupabaseVideoService');
    } catch (e) {
      developer.log('❌ Erreur lors de l\'ajout: $e', name: 'SupabaseVideoService');
      throw Exception('Erreur lors de l\'ajout du film à la liste: $e');
    }
  }

  /// Retirer un film de la liste de l'utilisateur
  Future<void> removeMovieFromList({
    required String movieId,
    required String userId,
  }) async {
    try {
      developer.log('🗑️ Tentative de suppression - movieId: $movieId, userId: $userId', name: 'SupabaseVideoService');
      
      final result = await _client
          .from(_listeTableName)
          .delete()
          .eq('movieId', movieId)
          .eq('userId', userId)
          .select();
      
      developer.log('✅ Résultat de la suppression: $result', name: 'SupabaseVideoService');
      
      if (result.isEmpty) {
        developer.log('⚠️ Aucune ligne supprimée - vérifier les valeurs des colonnes', name: 'SupabaseVideoService');
      }
      
      // Invalider le cache de la liste utilisateur
      await _invalidateCache('$_cacheKeyUserList$userId');
    } catch (e) {
      developer.log('❌ Erreur lors du retrait: $e', name: 'SupabaseVideoService');
      throw Exception('Erreur lors du retrait du film de la liste: $e');
    }
  }

  /// Récupérer les films de la liste de l'utilisateur
  Future<List<MovieModel>> fetchUserMovieList({
    required String userId,
  }) async {
    final cacheKey = '$_cacheKeyUserList$userId';
    
    final cachedData = await _getCachedMovies(cacheKey, _shortCacheDuration);
    if (cachedData != null) {
      developer.log('✅ Liste utilisateur récupérée du cache', name: 'SupabaseVideoService');
      return cachedData;
    }

    try {
      developer.log('🔍 Récupération liste utilisateur - userId: $userId', name: 'SupabaseVideoService');
      
      // Récupérer les IDs des films dans la liste de l'utilisateur
      final listeResponse = await _client
          .from(_listeTableName)
          .select('movieId')
          .eq('userId', userId)
          .order('created_at', ascending: false);
      
      final movieIds = (listeResponse as List)
          .map((item) {
            final id = item['movieId'];
            // movieId peut être int ou String selon la base de données
            return id?.toString();
          })
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      
      if (movieIds.isEmpty) {
        developer.log('📭 Liste utilisateur vide', name: 'SupabaseVideoService');
        return [];
      }
      
      // Récupérer les informations complètes des films
      final moviesResponse = await _client
          .from(_tableName)
          .select()
          .inFilter('id', movieIds);
      
      final movies = (moviesResponse as List)
          .map((json) => MovieModel.fromJson(json))
          .toList();
      
      // Trier les films dans l'ordre de la liste
      movies.sort((a, b) {
        final indexA = movieIds.indexOf(a.id);
        final indexB = movieIds.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
      
      await _cacheMovies(cacheKey, movies);
      developer.log('✅ ${movies.length} films récupérés de la liste utilisateur', name: 'SupabaseVideoService');
      
      return movies;
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la récupération de la liste: $e', error: e, stackTrace: stackTrace, name: 'SupabaseVideoService');
      throw Exception('Erreur lors de la récupération de la liste utilisateur: $e');
    }
  }

  // ===== Méthodes de gestion du cache =====

  /// Récupérer les films du cache si valide
  Future<List<MovieModel>?> _getCachedMovies(String key, Duration maxAge) async {
    try {
      final box = await Hive.openBox('movie_cache');
      final cached = box.get(key);
      
      if (cached != null && cached is Map) {
        final timestamp = cached['timestamp'] as int?;
        final data = cached['data'] as List?;
        
        if (timestamp != null && data != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (cacheAge < maxAge.inMilliseconds) {
            return data.map((json) => MovieModel.fromJson(Map<String, dynamic>.from(json))).toList();
          }
        }
      }
    } catch (e) {
      developer.log('Erreur lors de la lecture du cache: $e', name: 'SupabaseVideoService');
    }
    return null;
  }

  /// Mettre en cache une liste de films
  Future<void> _cacheMovies(String key, List<MovieModel> movies) async {
    try {
      final box = await Hive.openBox('movie_cache');
      await box.put(key, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': movies.map((m) => m.toJson()).toList(),
      });
    } catch (e) {
      developer.log('Erreur lors de la mise en cache: $e', name: 'SupabaseVideoService');
    }
  }

  /// Invalider le cache pour un préfixe de clé
  Future<void> _invalidateCache(String keyPrefix) async {
    try {
      final box = await Hive.openBox('movie_cache');
      final keysToDelete = box.keys.where((k) => k.toString().startsWith(keyPrefix)).toList();
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      developer.log('Cache invalidé pour: $keyPrefix', name: 'SupabaseVideoService');
    } catch (e) {
      developer.log('Erreur lors de l\'invalidation du cache: $e', name: 'SupabaseVideoService');
    }
  }

  /// Vider tout le cache
  Future<void> clearAllCache() async {
    try {
      final box = await Hive.openBox('movie_cache');
      await box.clear();
      developer.log('Tout le cache a été vidé', name: 'SupabaseVideoService');
    } catch (e) {
      developer.log('Erreur lors du vidage du cache: $e', name: 'SupabaseVideoService');
    }
  }

  // ==================== GESTION DES LECTURES ====================

  /// Récupérer ou créer une lecture pour un contenu
  /// Retourne la lecture existante la plus récente si elle existe, sinon en crée une nouvelle
  Future<LectureModel> getOrCreateLecture({
    required String videoId,
    required String userId,
  }) async {
    try {
      developer.log('🔍 Recherche lecture - videoId: $videoId, userId: $userId',
          name: 'SupabaseVideoService');
      
      // Chercher une lecture existante (la plus récente)
      final existingLecture = await _client
          .from(_lectureTableName)
          .select()
          .eq('idmovie', videoId)
          .eq('iduser', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existingLecture != null) {
        developer.log(
          '✅ Lecture existante trouvée:\n'
          '   - ID: ${existingLecture['id']}\n'
          '   - lastReading: ${existingLecture['lastReading']}\n'
          '   - duree: ${existingLecture['duree']}\n'
          '   - JSON complet: $existingLecture',
          name: 'SupabaseVideoService'
        );
        return LectureModel.fromJson(existingLecture);
      }

      developer.log('➕ Création nouvelle lecture',
          name: 'SupabaseVideoService');
      
      // Créer une nouvelle lecture
      final now = DateTime.now();
      final newLecture = await _client
          .from(_lectureTableName)
          .insert({
            'idmovie': videoId,
            'iduser': userId,
            'readingstart': now.toIso8601String(),
            'duree': 0,
          })
          .select()
          .single();

      developer.log('✅ Nouvelle lecture créée: ${newLecture['id']}',
          name: 'SupabaseVideoService');
      return LectureModel.fromJson(newLecture);
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la récupération/création de lecture: $e',
          error: e,
          stackTrace: stackTrace,
          name: 'SupabaseVideoService');
      rethrow;
    }
  }

  /// Mettre à jour la durée de lecture en incrémentant la durée existante
  Future<void> updateLectureDuration({
    required String lectureId,
    required int duree,
  }) async {
    try {
      developer.log(
        '💾 SUPABASE UPDATE:\n'
        '   - Table: $_lectureTableName\n'
        '   - lectureId: $lectureId\n'
        '   - duree à ajouter: $duree',
        name: 'SupabaseVideoService',
      );
      
      // 1. Récupérer la durée actuelle
      final currentData = await _client
          .from(_lectureTableName)
          .select('duree')
          .eq('id', lectureId)
          .single();
      
      final currentDuree = currentData['duree'] as int? ?? 0;
      final newDuree = currentDuree + duree;
      
      developer.log(
        '📊 CALCUL DURÉE:\n'
        '   - Durée actuelle: $currentDuree\n'
        '   - Durée à ajouter: $duree\n'
        '   - Nouvelle durée: $newDuree',
        name: 'SupabaseVideoService',
      );
      
      // 2. Convertir la nouvelle durée en format HH:MM:SS
      final hours = duree ~/ 3600;
      final minutes = (duree % 3600) ~/ 60;
      final seconds = duree % 60;
      final timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      // 3. Mettre à jour avec la nouvelle durée
      final response = await _client
          .from(_lectureTableName)
          .update({
            'duree': newDuree,
            'lastReading': timeString,
          })
          .eq('id', lectureId)
          .select();
      
      developer.log(
        '✅ SUPABASE RESPONSE:\n'
        '   - Response: $response\n'
        '   - Durée mise à jour: $newDuree secondes\n'
        '   - lastReading: $timeString',
        name: 'SupabaseVideoService',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ SUPABASE ERROR:\n'
        '   - lectureId: $lectureId\n'
        '   - duree: $duree\n'
        '   - Error: $e',
        error: e,
        stackTrace: stackTrace,
        name: 'SupabaseVideoService',
      );
      rethrow;
    }
  }

  /// Marquer une lecture comme terminée
  Future<void> completeLecture({
    required String lectureId,
    required int finalDuration,
  }) async {
    try {
      developer.log('🏁 Finalisation lecture - lectureId: $lectureId, durée finale: $finalDuration',
          name: 'SupabaseVideoService');
      
      final now = DateTime.now();
      await _client
          .from(_lectureTableName)
          .update({
            'readingend': now.toIso8601String(),
            'duree': finalDuration,
          })
          .eq('id', lectureId);

      developer.log('✅ Lecture terminée avec durée: $finalDuration secondes',
          name: 'SupabaseVideoService');
    } catch (e, stackTrace) {
      developer.log('❌ Erreur lors de la finalisation de lecture: $e',
          error: e,
          stackTrace: stackTrace,
          name: 'SupabaseVideoService');
      rethrow;
    }
  }
}