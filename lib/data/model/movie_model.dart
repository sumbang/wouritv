import 'package:wouritv/domain/entitie/movie_entity.dart';

/// Modèle de données pour la conversion JSON ↔ Dart
class MovieModel {
  final String id;
  final String? title;
  final String? description;
  final String? categorie;
  final String? paiement;
  final String? banniere;
  final int? chaineId;
  final int? prix;
  final DateTime? createdAt;

  const MovieModel({
    required this.id,
    this.title,
    this.description,
    this.categorie,
    this.paiement,
    this.banniere,
    this.chaineId,
    this.prix,
    this.createdAt,
  });

  /// Créer un MovieModel depuis un JSON (données Supabase)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'].toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      categorie: json['categorie'] as String?,
      paiement: json['paiement'] as String?,
      banniere: json['banniere'] as String?,
      chaineId: json['chaineId'] as int?,
      prix: json['prix'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convertir en JSON pour envoyer à Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': int.tryParse(id) ?? id,
      'title': title,
      'description': description,
      'categorie': categorie,
      'paiement': paiement,
      'banniere': banniere,
      'chaineId': chaineId,
      'prix': prix,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Convertir le modèle en entité
  MovieEntity toEntity() {
    return MovieEntity(
      id: id,
      title: title ?? '',
      description: description ?? '', 
      categorie: categorie ?? '',
      paiement: paiement ?? '',
      banniere: banniere ?? '',
      chaine: chaineId ?? 0,
      prix: prix ?? 0,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Créer une copie avec modifications
  MovieModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categorie,
    String? paiement,
    String? banniere,
    int? chaineId,
    int? prix,
    DateTime? createdAt,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      paiement: paiement ?? this.paiement,
      banniere: banniere ?? this.banniere,
      chaineId: chaineId ?? this.chaineId,
      prix: prix ?? this.prix,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
