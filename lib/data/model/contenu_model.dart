import 'package:wouritv/domain/entitie/contenu_entity.dart';

/// Modèle de données pour la conversion JSON ↔ Dart
class ContenuModel {
  final String id;
  final String? title;
  final String? videoUrl;
  final int movieId;
  final String? duree; // Changer de int à String
  final DateTime? createdAt;
  final String? lastReading; // Temps de lecture au format HH:MM:SS
  final String? lectureId; // ID de la lecture en cours

  const ContenuModel({
    required this.id,
    this.title,
    this.videoUrl,
    required this.movieId,
    this.duree,
    this.createdAt,
    this.lastReading,
    this.lectureId,
  });

  /// Créer un ContenuModel depuis un JSON (données Supabase)
  factory ContenuModel.fromJson(Map<String, dynamic> json) {
    return ContenuModel(
      id: json['id'].toString(),
      title: json['title'] as String?,
      videoUrl: json['videoId'] as String?,
      movieId: json['movieId'] as int,
      duree: json['duree'] as String?, // Lire comme String
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastReading: json['lastReading'] as String?,
      lectureId: json['lectureId'] as String?,
    );
  }

  /// Convertir en JSON pour envoyer à Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'title': title,
      'videoId': videoUrl,
      'movieId': movieId,
      'duree': duree,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Convertir le modèle en entité
  ContenuEntity toEntity() {
    return ContenuEntity(
      id: id,
      movieId: movieId,
      title: title ?? '',
      videoId: videoUrl,
      duree: duree,
      createdAt: createdAt ?? DateTime.now(),
      lastReading: lastReading,
      lectureId: lectureId,
    );
  }

  /// Créer une copie avec modifications
  ContenuModel copyWith({
    String? id,
    String? title,
    String? videoUrl,
    int? movieId,
    DateTime? createdAt,
    String? lastReading,
    String? lectureId,
  }) {
    return ContenuModel(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      movieId: movieId ?? this.movieId,
      createdAt: createdAt ?? this.createdAt,
      lastReading: lastReading ?? this.lastReading,
      lectureId: lectureId ?? this.lectureId,
    );
  }
}
