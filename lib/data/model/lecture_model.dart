import 'package:wouritv/domain/entitie/lecture_entity.dart';

/// Modèle de données pour la table lecture
class LectureModel {
  final String id;
  final DateTime createdAt;
  final String idmovie; // VideoId YouTube
  final DateTime readingstart;
  final DateTime? readingend;
  final String iduser;
  final int duree;
  final String? lastReading; // Heure de la dernière mise à jour (HH:MM:SS)

  const LectureModel({
    required this.id,
    required this.createdAt,
    required this.idmovie,
    required this.readingstart,
    this.readingend,
    required this.iduser,
    required this.duree,
    this.lastReading,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    return LectureModel(
      id: json['id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      idmovie: json['idmovie'] as String, // VideoId YouTube
      readingstart: DateTime.parse(json['readingstart'] as String),
      readingend: json['readingend'] != null
          ? DateTime.parse(json['readingend'] as String)
          : null,
      iduser: json['iduser'] as String,
      duree: json['duree'] as int,
      lastReading: json['lastReading'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'idmovie': idmovie,
      'readingstart': readingstart.toIso8601String(),
      'readingend': readingend?.toIso8601String(),
      'iduser': iduser,
      'duree': duree,
      'lastReading': lastReading,
    };
  }

  LectureEntity toEntity() {
    return LectureEntity(
      id: id,
      createdAt: createdAt,
      idmovie: idmovie,
      readingstart: readingstart,
      readingend: readingend,
      iduser: iduser,
      duree: duree,
      lastReading: lastReading,
    );
  }
}
