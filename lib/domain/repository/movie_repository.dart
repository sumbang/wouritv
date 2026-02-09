import 'package:wouritv/domain/entitie/movie_content_entity.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';

/// Interface du repository (contrat)
/// Définit les opérations possibles sans se soucier de l'implémentation
abstract class MovieRepository {

  /// Récupérer une vidéo par ID
  Future<MovieWithContentsEntity> getMovieById(String id, {String? userId});

  /// Récupérer les vidéos par catégorie
  Future<List<MovieEntity>> getMoviesByCategory(String category, {int page = 1, int limit = 20});

  /// Rechercher des vidéos
  Future<List<MovieEntity>> searchMovies(String query);

    /// Rechercher des vidéos dans la liste de l'utilisateur
  Future<List<MovieEntity>> getListMovie(String userId);

  /// Récupérer les dernieres vidéos ajoutées
  Future<List<MovieEntity>> getLatestsMovies({int limit = 20});

  /// Récupérer les plus videos recommandees
  Future<List<MovieEntity>> getRecommandedMovies({int limit = 20});

    /// Récupérer les vidéos aléatoires
  Future<List<MovieEntity>> getRandomsMovies({int limit = 20});

  /// Récupérer les videoes les plus regardées
  Future<List<MovieEntity>> getMostWatchedMovies({int limit = 20});

  //recupérer les vidéos par chaîne
  Future<List<MovieEntity>> getMoviesByChannel(int channelId, {int page = 1, int limit = 20});

  // recommander une video ou pas
  Future<void> recommendMovie(String movieId, String userId, bool recommend);

  // ajouter un film a la liste de l'utilisateur
  Future<void> addMovieToList(String movieId, String userId);

  // retirer un film de la liste de l'utilisateur
  Future<void> removeMovieFromList(String movieId, String userId);
  
}
