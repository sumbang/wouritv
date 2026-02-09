import 'package:wouritv/data/api/supabase_movie_service.dart';
import 'package:wouritv/domain/entitie/lecture_entity.dart';
import 'package:wouritv/domain/repository/lecture_repository.dart';

/// Implémentation du repository des lectures
class LectureRepositoryImpl implements LectureRepository {
  final SupabaseVideoService _videoService;

  LectureRepositoryImpl(this._videoService);

  @override
  Future<LectureEntity> getOrCreateLecture({
    required String videoId,
    required String userId,
  }) async {
    final lectureModel = await _videoService.getOrCreateLecture(
      videoId: videoId,
      userId: userId,
    );
    return lectureModel.toEntity();
  }

  @override
  Future<void> updateLectureDuration({
    required String lectureId,
    required int duree,
  }) async {
    await _videoService.updateLectureDuration(
      lectureId: lectureId,
      duree: duree,
    );
  }

  @override
  Future<void> completeLecture({
    required String lectureId,
    required int finalDuration,
  }) async {
    await _videoService.completeLecture(
      lectureId: lectureId,
      finalDuration: finalDuration,
    );
  }
}
