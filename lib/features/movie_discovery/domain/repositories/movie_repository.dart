import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/movie.dart';

abstract class MovieRepository {
  Future<Result<List<Movie>, Failure>> getRecommendations(String moodPrompt);
  Future<Result<String, Failure>> generatePromptWithFilter(String currentPrompt, Map<String, dynamic> filters);
}
