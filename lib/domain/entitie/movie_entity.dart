import 'package:equatable/equatable.dart';

/// Entité métier représentant une vidéo
/// Cette classe est indépendante de toute implémentation technique
class MovieEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String banniere;
  final String paiement;
  final String categorie;
  final DateTime createdAt;
  final int prix;
  final int chaine;

  const MovieEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.banniere,
    required this.paiement,
    required this.categorie,
    required this.createdAt,
    required this.prix,
    required this.chaine,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        banniere,
        paiement,
        categorie,
        createdAt,
        prix,
        chaine,
      ];
}
