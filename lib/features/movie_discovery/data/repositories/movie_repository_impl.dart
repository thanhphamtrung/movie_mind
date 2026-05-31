import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_datasource.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource remoteDataSource;

  const MovieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Movie>, Failure>> getRecommendations(String moodPrompt) async {
    try {
      final remoteMovies = await remoteDataSource.getRecommendations(moodPrompt);
      return Success(remoteMovies);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
