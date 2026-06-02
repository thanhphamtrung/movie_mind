import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_recommendations.dart';
import '../../domain/usecases/generate_prompt_with_filter.dart';
import 'movie_discovery_state.dart';

class MovieDiscoveryCubit extends Cubit<MovieDiscoveryState> {
  final GetRecommendations getRecommendations;
  final GeneratePromptWithFilter generatePromptWithFilterUseCase;

  MovieDiscoveryCubit({
    required this.getRecommendations,
    required this.generatePromptWithFilterUseCase,
  }) : super(const MovieDiscoveryInitial());

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
  
  Future<void> generatePrompt(String currentPrompt, Map<String, dynamic> filters) async {
    emit(const MovieDiscoveryPromptGenerating());
    final result = await generatePromptWithFilterUseCase(
      GeneratePromptWithFilterParams(currentPrompt: currentPrompt, filters: filters)
    );
    
    switch (result) {
      case Success(value: final newPrompt):
        emit(MovieDiscoveryPromptGenerated(newPrompt));
      case FailureResult(error: final failure):
        emit(MovieDiscoveryError(failure.message));
    }
  }

  void reset() {
    emit(const MovieDiscoveryInitial());
  }
}
