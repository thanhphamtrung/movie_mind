import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/movie.dart';
import '../repositories/movie_repository.dart';

class GetRecommendations implements UseCase<List<Movie>, String> {
  final MovieRepository repository;

  const GetRecommendations(this.repository);

  @override
  Future<Result<List<Movie>, Failure>> call(String moodPrompt) async {
    return await repository.getRecommendations(moodPrompt);
  }
}
