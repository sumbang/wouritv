import 'package:wouritv/domain/entitie/lecture_entity.dart';
import 'package:wouritv/domain/repository/lecture_repository.dart';

/// Use case pour récupérer ou créer une lecture
class GetOrCreateLectureUseCase {
  final LectureRepository repository;

  GetOrCreateLectureUseCase(this.repository);

  Future<LectureEntity> execute({
    required String videoId,
    required String userId,
  }) async {
    return await repository.getOrCreateLecture(
      videoId: videoId,
      userId: userId,
    );
  }
}

/// Use case pour mettre à jour la durée de lecture
class UpdateLectureDurationUseCase {
  final LectureRepository repository;

  UpdateLectureDurationUseCase(this.repository);

  Future<void> execute({
    required String lectureId,
    required int duree,
  }) async {
    await repository.updateLectureDuration(
      lectureId: lectureId,
      duree: duree,
    );
  }
}

/// Use case pour marquer une lecture comme terminée
class CompleteLectureUseCase {
  final LectureRepository repository;

  CompleteLectureUseCase(this.repository);

  Future<void> execute({
    required String lectureId,
    required int finalDuration,
  }) async {
    await repository.completeLecture(
      lectureId: lectureId,
      finalDuration: finalDuration,
    );
  }
}
