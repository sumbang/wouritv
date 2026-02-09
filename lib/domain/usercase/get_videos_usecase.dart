import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/domain/entitie/movie_content_entity.dart';
import 'package:wouritv/domain/repository/movie_repository.dart';

/// Use case pour récupérer une vidéo par ID avec ses contenus
class GetMovieByIdUseCase {
  final MovieRepository repository;

  GetMovieByIdUseCase(this.repository);

  Future<MovieWithContentsEntity> execute(String id, {String? userId}) async {
    return await repository.getMovieById(id, userId: userId);
  }
}

/// Use case pour récupérer les vidéos par catégorie
class GetMoviesByCategoryUseCase {
  final MovieRepository repository;

  GetMoviesByCategoryUseCase(this.repository);

  Future<List<MovieEntity>> execute(String category, {int page = 1, int limit = 20}) async {
    return await repository.getMoviesByCategory(category, page: page, limit: limit);
  }
}

/// Use case pour rechercher des vidéos
class SearchMoviesUseCase {
  final MovieRepository repository;

  SearchMoviesUseCase(this.repository);

  Future<List<MovieEntity>> execute(String query) async {
    if (query.isEmpty) {
      return [];
    }
    return await repository.searchMovies(query);
  }
}

/// Use case pour rechercher des vidéos d'une liste utilisateur
class GetListMovieUseCase {
  final MovieRepository repository;

  GetListMovieUseCase(this.repository);

  Future<List<MovieEntity>> execute(String userId) async {
    if (userId.isEmpty) {
      return [];
    }
    return await repository.getListMovie(userId);
  }
}

/// Use case pour récupérer les dernières vidéos ajoutées
class GetLatestMoviesUseCase {
  final MovieRepository repository;

  GetLatestMoviesUseCase(this.repository);

  Future<List<MovieEntity>> execute({int limit = 100}) async {
    return await repository.getLatestsMovies(limit: limit);
  }
}

/// Use case pour récupérer les vidéos les plus recommandées
class GetRecommendedMoviesUseCase {
  final MovieRepository repository;

  GetRecommendedMoviesUseCase(this.repository);

  Future<List<MovieEntity>> execute({int limit = 100}) async {
    return await repository.getRecommandedMovies(limit: limit);
  }
}

/// Use case pour récupérer les vidéos les plus regardées
class GetMostWatchedMoviesUseCase {
  final MovieRepository repository;

  GetMostWatchedMoviesUseCase(this.repository);

  Future<List<MovieEntity>> execute({int limit = 100}) async {
    return await repository.getMostWatchedMovies(limit: limit);
  }
}

/// Use case pour récupérer les vidéos aleatoires
class GetRandomMoviesUseCase {
  final MovieRepository repository;

  GetRandomMoviesUseCase(this.repository);

  Future<List<MovieEntity>> execute({int limit = 20}) async {
    return await repository.getRandomsMovies(limit: limit);
  }
}

/// Use case pour récupérer les vidéos par chaîne
class GetMoviesByChannelUseCase {
  final MovieRepository repository;

  GetMoviesByChannelUseCase(this.repository);

  Future<List<MovieEntity>> execute(int channelId, {int page = 1, int limit = 20}) async {
    return await repository.getMoviesByChannel(channelId, page: page, limit: limit);
  }
}

/// Use case pour recommander ou non une vidéo
class RecommendMovieUseCase {
  final MovieRepository repository;

  RecommendMovieUseCase(this.repository);

  Future<void> execute({
    required String movieId,
    required String userId,
    required bool recommend,
  }) async {
    return await repository.recommendMovie(movieId, userId, recommend);
  }
}

/// Use case pour ajouter un film à la liste de l'utilisateur
class AddMovieToListUseCase {
  final MovieRepository repository;

  AddMovieToListUseCase(this.repository);
  Future<void> execute({
    required String movieId,
    required String userId,
  }) async {
    return await repository.addMovieToList(movieId, userId);
  }
}

/// Use case pour retirer un film de la liste de l'utilisateur
class RemoveMovieFromListUseCase {
  final MovieRepository repository;

  RemoveMovieFromListUseCase(this.repository);
  Future<void> execute({
    required String movieId,
    required String userId,
  }) async {
    return await repository.removeMovieFromList(movieId, userId);
  }
}