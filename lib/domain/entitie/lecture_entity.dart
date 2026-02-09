import 'package:equatable/equatable.dart';

/// Entité représentant une lecture de vidéo
class LectureEntity extends Equatable {
  final String id;
  final DateTime createdAt;
  final String idmovie; // VideoId YouTube
  final DateTime readingstart;
  final DateTime? readingend;
  final String iduser;
  final int duree; // Durée en secondes
  final String? lastReading; // Heure de la dernière mise à jour (HH:MM:SS)

  const LectureEntity({
    required this.id,
    required this.createdAt,
    required this.idmovie,
    required this.readingstart,
    this.readingend,
    required this.iduser,
    required this.duree,
    this.lastReading,
  });

  @override
  List<Object?> get props => [
        id,
        createdAt,
        idmovie,
        readingstart,
        readingend,
        iduser,
        duree,
        lastReading,
      ];

  LectureEntity copyWith({
    String? id,
    DateTime? createdAt,
    String? idmovie,
    DateTime? readingstart,
    DateTime? readingend,
    String? iduser,
    int? duree,
    String? lastReading,
  }) {
    return LectureEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      idmovie: idmovie ?? this.idmovie,
      readingstart: readingstart ?? this.readingstart,
      readingend: readingend ?? this.readingend,
      iduser: iduser ?? this.iduser,
      duree: duree ?? this.duree,
      lastReading: lastReading ?? this.lastReading,
    );
  }
}
