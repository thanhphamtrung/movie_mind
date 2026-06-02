import 'package:equatable/equatable.dart';
import '../../domain/entities/movie.dart';

sealed class MovieDiscoveryState extends Equatable {
  const MovieDiscoveryState();

  @override
  List<Object?> get props => [];
}

class MovieDiscoveryInitial extends MovieDiscoveryState {
  const MovieDiscoveryInitial();
}

class MovieDiscoveryLoading extends MovieDiscoveryState {
  const MovieDiscoveryLoading();
}

class MovieDiscoveryLoaded extends MovieDiscoveryState {
  final List<Movie> movies;
  final String moodPrompt;

  const MovieDiscoveryLoaded({required this.movies, required this.moodPrompt});

  @override
  List<Object?> get props => [movies, moodPrompt];
}

class MovieDiscoveryError extends MovieDiscoveryState {
  final String message;

  const MovieDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}

class MovieDiscoveryPromptGenerating extends MovieDiscoveryState {
  const MovieDiscoveryPromptGenerating();
}

class MovieDiscoveryPromptGenerated extends MovieDiscoveryState {
  final String newPrompt;

  const MovieDiscoveryPromptGenerated(this.newPrompt);

  @override
  List<Object?> get props => [newPrompt];
}
