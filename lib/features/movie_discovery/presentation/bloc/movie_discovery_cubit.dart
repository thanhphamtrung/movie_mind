import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_recommendations.dart';
import 'movie_discovery_state.dart';

class MovieDiscoveryCubit extends Cubit<MovieDiscoveryState> {
  final GetRecommendations getRecommendations;

  MovieDiscoveryCubit({required this.getRecommendations})
      : super(const MovieDiscoveryInitial());

  Future<void> fetchMoviesForMood(String moodPrompt) async {
    emit(const MovieDiscoveryLoading());
    final result = await getRecommendations(moodPrompt);
    switch (result) {
      case Success(value: final movies):
        if (movies.isEmpty) {
          emit(const MovieDiscoveryError('Không tìm thấy bộ phim nào phù hợp với tâm trạng của bạn. Hãy thử mô tả khác nhé!'));
        } else {
          emit(MovieDiscoveryLoaded(movies: movies, moodPrompt: moodPrompt));
        }
      case FailureResult(error: final failure):
        emit(MovieDiscoveryError(failure.message));
    }
  }

  void reset() {
    emit(const MovieDiscoveryInitial());
  }
}
