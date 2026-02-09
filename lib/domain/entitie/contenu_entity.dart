import 'package:equatable/equatable.dart';

/// Entité représentant un contenu (épisode, vidéo, etc.)
class ContenuEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final String title;
  final String? videoId;
  final int? movieId;
  final String? duree; // Durée en secondes
  final String? banniere;
  final String? lastReading; // Temps de lecture au format HH:MM:SS
  final String? lectureId; // ID de la lecture en cours

  const ContenuEntity({
    required this.id,
    required this.createdAt,
    required this.title,
    this.videoId,
    this.movieId,
    this.duree,
    this.banniere,
    this.lastReading,
    this.lectureId,
  });

  @override
  List<Object?> get props => [id, createdAt, title, videoId, movieId, duree, banniere, lastReading, lectureId];

  ContenuEntity copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? videoId,
    int? movieId,
    String? duree,
    String? banniere,
    String? lastReading,
    String? lectureId,
  }) {
    return ContenuEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      videoId: videoId ?? this.videoId,
      movieId: movieId ?? this.movieId,
      duree: duree ?? this.duree,
      banniere: banniere ?? this.banniere,
      lastReading: lastReading ?? this.lastReading,
      lectureId: lectureId ?? this.lectureId,
    );
  }
}