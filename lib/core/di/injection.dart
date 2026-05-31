import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Core imports
import '../../features/movie_discovery/data/datasources/movie_remote_datasource.dart';
import '../../features/movie_discovery/data/repositories/movie_repository_impl.dart';
import '../../features/movie_discovery/domain/repositories/movie_repository.dart';
import '../../features/movie_discovery/domain/usecases/get_recommendations.dart';
import '../../features/movie_discovery/presentation/bloc/movie_discovery_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => dotenv);
  sl.registerLazySingleton<GenerativeModel>(
    () => GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    ),
  );

  // Features - Movie Discovery
  
  // Data Sources
  sl.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSourceImpl(
      generativeModel: sl(),
      dio: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRecommendations(sl()));

  // Blocs / Cubits
  sl.registerFactory(() => MovieDiscoveryCubit(getRecommendations: sl()));
}
