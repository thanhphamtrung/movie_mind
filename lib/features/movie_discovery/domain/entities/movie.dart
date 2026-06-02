import 'package:equatable/equatable.dart';

class Movie extends Equatable {
  final String id;
  final String title;
  final String posterUrl;
  final String overview;
  final double rating;
  final String releaseYear;
  final List<String> genres;
  final String? trailerYoutubeId;
  final String reason;

  const Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.overview,
    required this.rating,
    required this.releaseYear,
    required this.genres,
    this.trailerYoutubeId,
    this.reason = '',
  });

  @override
  List<Object?> get props => [
        id,
        title,
        posterUrl,
        overview,
        rating,
        releaseYear,
        genres,
        trailerYoutubeId,
        reason,
      ];
}
