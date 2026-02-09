import 'package:wouritv/data/api/supabase_movie_service.dart';
import 'package:wouritv/domain/entitie/movie_content_entity.dart';
import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/domain/repository/movie_repository.dart';

/// Implémentation concrète du MovieRepository
/// Fait le pont entre la couche domaine et la couche data
class MovieRepositoryImpl implements MovieRepository {
  final SupabaseVideoService _videoService;

  MovieRepositoryImpl(this._videoService);

  @override
  Future<MovieWithContentsEntity> getMovieById(String id, {String? userId}) async {
    try {
      final movie = await _videoService.fetchMovieById(id, userId: userId);
      return movie.toEntity();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération de la vidéo: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getMoviesByCategory(String category, {int page = 1, int limit = 20}) async {
    try {
      final movies = await _videoService.fetchMoviesByCategory(
        category: category,
        page: page,
        limit: limit,
      );
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des vidéos par catégorie: $e');
    }
  }

  @override
  Future<List<MovieEntity>> searchMovies(String query) async {
    try {
      final movies = await _videoService.searchMovies(query);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la recherche de vidéos: $e');
    }
  }

    @override
  Future<List<MovieEntity>> getListMovie(String userId) async {
    try {
      final movies = await _videoService.fetchUserMovieList(userId: userId);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération de la liste de vidéos de l\'utilisateur: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getLatestsMovies({int limit = 20}) async {
    try {
      final movies = await _videoService.fetchLatestMovies(limit : limit);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des dernières vidéos: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getRandomsMovies({int limit = 20}) async {
    try {
      final movies = await _videoService.fetchRandomMovies(limit : limit);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des vidéos aléatoires: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getRecommandedMovies({int limit = 20}) async {
    try {
      final movies = await _videoService.fetchMostRecommendedMovies(limit: limit);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des vidéos recommandées: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getMostWatchedMovies({int limit = 20}) async {
    try {
      final movies = await _videoService.mostWatchingMovie(limit: limit);
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des vidéos les plus regardées: $e');
    }
  }

  @override
  Future<List<MovieEntity>> getMoviesByChannel(int channelId, {int page = 1, int limit = 20}) async {
    try {
      final movies = await _videoService.fetchMoviesByChannel(
        channel: channelId,
        page: page,
        limit: limit,
      );
      return movies.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Repository: Erreur lors de la récupération des vidéos par chaîne: $e');
    }
  }

  @override
  Future<void> recommendMovie(String movieId, String userId, bool recommend) async {
    try {
      await _videoService.recommandMovie(
        movieId: movieId,
        userId: userId,
        isRecommended: recommend,
      );
    } catch (e) {
      throw Exception('Repository: Erreur lors de la recommandation de la vidéo: $e');
    }
  }
  
  @override
  Future<void> addMovieToList(String movieId, String userId) async {
       try {
      await _videoService.addMovieToList(
        movieId: movieId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Repository: Erreur lors de l\'ajout de la vidéo à la liste: $e');
    }
  }
  
  @override
  Future<void> removeMovieFromList(String movieId, String userId) async {
       try {
      await _videoService.removeMovieFromList(
        movieId: movieId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Repository: Erreur lors de la suppression de la vidéo de la liste: $e');
    }
  }




}
