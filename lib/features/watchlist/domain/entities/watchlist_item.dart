import 'package:equatable/equatable.dart';

class WatchlistItem extends Equatable {
  final String id;
  final String title;
  final String posterUrl;
  final double rating;
  final String releaseYear;
  final String? trailerYoutubeId;
  final DateTime savedAt;

  const WatchlistItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.releaseYear,
    this.trailerYoutubeId,
    required this.savedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        posterUrl,
        rating,
        releaseYear,
        trailerYoutubeId,
        savedAt,
      ];
}
