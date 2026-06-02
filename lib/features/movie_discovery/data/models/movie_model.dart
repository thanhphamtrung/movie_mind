import '../../domain/entities/movie.dart';

class MovieModel extends Movie {
  const MovieModel({
    required super.id,
    required super.title,
    required super.posterUrl,
    required super.overview,
    required super.rating,
    required super.releaseYear,
    required super.genres,
    super.trailerYoutubeId,
    super.reason,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as String,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
      overview: json['overview'] as String,
      rating: (json['rating'] as num).toDouble(),
      releaseYear: json['releaseYear'] as String,
      genres: List<String>.from(json['genres'] as List),
      trailerYoutubeId: json['trailerYoutubeId'] as String?,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'overview': overview,
      'rating': rating,
      'releaseYear': releaseYear,
      'genres': genres,
      'trailerYoutubeId': trailerYoutubeId,
      'reason': reason,
    };
  }

  MovieModel copyWith({
    String? id,
    String? title,
    String? posterUrl,
    String? overview,
    double? rating,
    String? releaseYear,
    List<String>? genres,
    String? trailerYoutubeId,
    String? reason,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      releaseYear: releaseYear ?? this.releaseYear,
      genres: genres ?? this.genres,
      trailerYoutubeId: trailerYoutubeId ?? this.trailerYoutubeId,
      reason: reason ?? this.reason,
    );
  }
}
