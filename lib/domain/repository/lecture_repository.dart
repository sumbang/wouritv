import 'package:wouritv/domain/entitie/lecture_entity.dart';

/// Repository abstrait pour la gestion des lectures de vidéos
abstract class LectureRepository {
  /// Récupérer ou créer une lecture pour un contenu
  /// Retourne la lecture existante non terminée si elle existe, sinon en crée une nouvelle
  Future<LectureEntity> getOrCreateLecture({
    required String videoId,
    required String userId,
  });

  /// Mettre à jour la durée de lecture
  Future<void> updateLectureDuration({
    required String lectureId,
    required int duree,
  });

  /// Marquer une lecture comme terminée
  Future<void> completeLecture({
    required String lectureId,
    required int finalDuration,
  });
}
