import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/movie_discovery/presentation/bloc/movie_discovery_cubit.dart';
import 'features/movie_discovery/presentation/pages/movie_swipe_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Service Locator (Dependency Injection)
  await di.init();
  
  runApp(const MovieMindApp());
}

class MovieMindApp extends StatelessWidget {
  const MovieMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MovieDiscoveryCubit>(
          create: (_) => di.sl<MovieDiscoveryCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'MovieMind - Mood-based Movie Discovery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MovieSwipePage(),
      ),
    );
  }
}
