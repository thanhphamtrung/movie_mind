import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/movie_repository.dart';

class GeneratePromptWithFilterParams {
  final String currentPrompt;
  final Map<String, dynamic> filters;

  const GeneratePromptWithFilterParams({
    required this.currentPrompt,
    required this.filters,
  });
}

class GeneratePromptWithFilter implements UseCase<String, GeneratePromptWithFilterParams> {
  final MovieRepository repository;

  const GeneratePromptWithFilter(this.repository);

  @override
  Future<Result<String, Failure>> call(GeneratePromptWithFilterParams params) async {
    return await repository.generatePromptWithFilter(params.currentPrompt, params.filters);
  }
}
