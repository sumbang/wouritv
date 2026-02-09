import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wouritv/data/api/supabase_movie_service.dart';
import 'package:wouritv/data/api/premium_video_service.dart';
import 'package:wouritv/data/repository/movie_repository_impl.dart';
import 'package:wouritv/data/repository/lecture_repository_impl.dart';
import 'package:wouritv/domain/repository/movie_repository.dart';
import 'package:wouritv/domain/repository/lecture_repository.dart';
import 'package:wouritv/domain/usercase/get_videos_usecase.dart';
import 'package:wouritv/domain/usercase/lecture_usecase.dart';

/// Provider pour le service Supabase Video
final movieServiceProvider = Provider<SupabaseVideoService>((ref) {
  return SupabaseVideoService();
});

/// Provider pour le service Premium Video
final premiumVideoServiceProvider = Provider<PremiumVideoService>((ref) {
  return PremiumVideoService();
});

/// Provider pour le repository Movie
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final service = ref.watch(movieServiceProvider);
  return MovieRepositoryImpl(service);
});

/// Provider pour le repository Lecture
final lectureRepositoryProvider = Provider<LectureRepository>((ref) {
  final service = ref.watch(movieServiceProvider);
  return LectureRepositoryImpl(service);
});

/// ================== PROVIDERS POUR LES USE CASES ==================

/// Provider pour récupérer un film par ID avec ses contenus
final getMovieByIdUseCaseProvider = Provider<GetMovieByIdUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetMovieByIdUseCase(repository);
});

/// Provider pour récupérer les films par catégorie
final getMoviesByCategoryUseCaseProvider = Provider<GetMoviesByCategoryUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetMoviesByCategoryUseCase(repository);
});

/// Provider pour rechercher des films
final searchMoviesUseCaseProvider = Provider<SearchMoviesUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return SearchMoviesUseCase(repository);
});

/// Provider pour rechercher des contenus d'une liste utilisateur
final getListMovieUseCaseProvider = Provider<GetListMovieUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetListMovieUseCase(repository);
});

/// Provider pour récupérer les derniers films ajoutés
final getLatestMoviesUseCaseProvider = Provider<GetLatestMoviesUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetLatestMoviesUseCase(repository);
});

/// Provider pour récupérer les films les plus recommandés
final getRecommendedMoviesUseCaseProvider = Provider<GetRecommendedMoviesUseCase>((ref) {
  final repository = ref.read(movieRepositoryProvider);
  return GetRecommendedMoviesUseCase(repository);
});

/// Provider pour récupérer les videos aléatoires
final getRandomMoviesUseCaseProvider = Provider<GetRandomMoviesUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetRandomMoviesUseCase(repository);
});

/// Provider pour récupérer les films les plus regardés
final getMostWatchedMoviesUseCaseProvider = Provider<GetMostWatchedMoviesUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetMostWatchedMoviesUseCase(repository);
});

/// Provider pour récupérer les films par chaîne
final getMoviesByChannelUseCaseProvider = Provider<GetMoviesByChannelUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return GetMoviesByChannelUseCase(repository);
});

/// Provider pour recommander un film
final recommendMovieUseCaseProvider = Provider<RecommendMovieUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return RecommendMovieUseCase(repository);
});

/// Provider pour ajouter un film à la liste de l'utilisateur
final addMovieToListUseCaseProvider = Provider<AddMovieToListUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return AddMovieToListUseCase(repository);
});

/// Provider pour retirer un film de la liste de l'utilisateur
final removeMovieFromListUseCaseProvider = Provider<RemoveMovieFromListUseCase>((ref) {
  final repository = ref.watch(movieRepositoryProvider);
  return RemoveMovieFromListUseCase(repository);
});

// ==================== PROVIDERS POUR LES LECTURES ====================

/// Provider pour récupérer ou créer une lecture
final getOrCreateLectureUseCaseProvider = Provider<GetOrCreateLectureUseCase>((ref) {
  final repository = ref.watch(lectureRepositoryProvider);
  return GetOrCreateLectureUseCase(repository);
});

/// Provider pour mettre à jour la durée de lecture
final updateLectureDurationUseCaseProvider = Provider<UpdateLectureDurationUseCase>((ref) {
  final repository = ref.watch(lectureRepositoryProvider);
  return UpdateLectureDurationUseCase(repository);
});

/// Provider pour marquer une lecture comme terminée
final completeLectureUseCaseProvider = Provider<CompleteLectureUseCase>((ref) {
  final repository = ref.watch(lectureRepositoryProvider);
  return CompleteLectureUseCase(repository);
});