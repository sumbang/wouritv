import 'package:wouritv/domain/entitie/movie_entity.dart';
import 'package:wouritv/domain/entitie/contenu_entity.dart';
class MovieWithContentsEntity {
  final MovieEntity movie;
  final List<ContenuEntity> contents;
  final bool isInList;
  final bool? userRecommendation;

  MovieWithContentsEntity({
    required this.movie,
    required this.contents,
    this.isInList = false,
    this.userRecommendation,
  });
}