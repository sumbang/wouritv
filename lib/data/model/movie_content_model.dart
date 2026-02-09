import 'package:wouritv/data/model/contenu_model.dart';
import 'package:wouritv/data/model/movie_model.dart';
import 'package:wouritv/domain/entitie/movie_content_entity.dart';

class MovieWithContentsResponse {
  final MovieModel movie;
  final List<ContenuModel> contents;
  final bool isInList;
  final bool? userRecommendation;

  MovieWithContentsResponse({
    required this.movie,
    required this.contents,
    this.isInList = false,
    this.userRecommendation,
  });

  MovieWithContentsEntity toEntity() {
    return MovieWithContentsEntity(
      movie: movie.toEntity(),
      contents: contents.map((c) => c.toEntity()).toList(),
      isInList: isInList,
      userRecommendation: userRecommendation,
    );
  }
}