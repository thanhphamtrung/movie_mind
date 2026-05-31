import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/movie.dart';
import '../bloc/movie_discovery_cubit.dart';
import '../bloc/movie_discovery_state.dart';
import '../widgets/mood_input_sheet.dart';

// Import watchlist page and save usecase to enable cross-feature integration
import '../../../watchlist/presentation/pages/watchlist_page.dart';

class MovieSwipePage extends StatefulWidget {
  const MovieSwipePage({super.key});

  @override
  State<MovieSwipePage> createState() => _MovieSwipePageState();
}

class _MovieSwipePageState extends State<MovieSwipePage> {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentIndex = 0;
  List<Movie> _currentMovies = [];

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _showMoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodInputSheet(
        onSubmitted: (mood) {
          context.read<MovieDiscoveryCubit>().fetchMoviesForMood(mood);
        },
      ),
    );
  }

  Future<void> _launchYoutube(String youtubeId) async {
    final Uri appUri = Uri.parse('youtube://watch?v=$youtubeId');
    final Uri webUri = Uri.parse('https://www.youtube.com/watch?v=$youtubeId');
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở liên kết YouTube!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _playTrailer(String? youtubeId) {
    if (youtubeId == null || youtubeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy trailer cho phim này!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final String parsedId = YoutubePlayer.convertUrlToId(youtubeId) ?? youtubeId;

    if (parsedId.length < 10 || parsedId.length > 12 || parsedId.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Trailer không khả dụng!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final YoutubePlayerController playerController = YoutubePlayerController(
      initialVideoId: parsedId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YoutubePlayer(
              controller: playerController,
              showVideoProgressIndicator: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _launchYoutube(youtubeId);
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.amber, size: 16),
                    label: const Text(
                      'Xem trên YouTube ↗',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MovieDiscoveryCubit, MovieDiscoveryState>(
        listener: (context, state) {
          if (state is MovieDiscoveryLoaded) {
            setState(() {
              _currentMovies = state.movies;
              _currentIndex = 0;
            });
          }
        },
        builder: (context, state) {
          final String? activePosterUrl =
              _currentMovies.isNotEmpty && _currentIndex < _currentMovies.length
                  ? _currentMovies[_currentIndex].posterUrl
                  : null;

          return Stack(
            children: [
              // 1. Cinematic Blurred Backdrop Poster matching current active card
              if (activePosterUrl != null)
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: activePosterUrl,
                        fit: BoxFit.cover,
                        httpHeaders: const {
                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                        },
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.background,
                        ),
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(color: AppColors.background),

              // 2. Main Page Layout
              SafeArea(
                child: Column(
                  children: [
                    // Header Appbar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'MovieMind',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [AppColors.primary, AppColors.secondary],
                                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.glassBorder),
                              ),
                            ),
                            icon: const Icon(Icons.bookmark_outline, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WatchlistPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Main Content / Swiper
                    Expanded(
                      child: _buildMainContent(state),
                    ),

                    // Floating Mood Input Trigger / Controls
                    _buildBottomControls(state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(MovieDiscoveryState state) {
    if (state is MovieDiscoveryInitial) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.movie_filter_outlined, size: 80, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              const Text(
                'Khám phá Điện ảnh cùng AI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mô tả tâm trạng hôm nay của bạn, AI sẽ chọn lọc những thước phim chuẩn xác nhất cho riêng bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _showMoodSheet,
                child: const Text('Nhập Tâm Trạng Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MovieDiscoveryLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'AI đang phân tích cảm xúc...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (state is MovieDiscoveryError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_very_dissatisfied, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showMoodSheet,
                child: const Text('Thử Lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MovieDiscoveryLoaded) {
      if (_currentIndex >= _currentMovies.length) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                const SizedBox(height: 16),
                const Text(
                  'Đã xem hết gợi ý!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy nhập một tâm trạng khác để tiếp tục tìm kiếm những bộ phim thú vị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _showMoodSheet,
                  child: const Text('Tìm Kiếm Mới'),
                ),
              ],
            ),
          ),
        );
      }

      return CardSwiper(
        controller: _swiperController,
        cardsCount: _currentMovies.length,
        initialIndex: _currentIndex,
        onSwipe: (previousIndex, currentIndex, direction) {
          setState(() {
            _currentIndex = currentIndex ?? _currentIndex + 1;
          });
          if (direction == CardSwiperDirection.right) {
            // Save to Watchlist
            final savedMovie = _currentMovies[previousIndex];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu "${savedMovie.title}" vào Watchlist'),
                action: SnackBarAction(
                  label: 'Xem',
                  textColor: AppColors.accent,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WatchlistPage(),
                      ),
                    );
                  },
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return true;
        },
        cardBuilder: (context, index, percentX, percentY) {
          final movie = _currentMovies[index];
          return _buildMovieCard(movie);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMovieCard(Movie movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Movie Poster
            CachedNetworkImage(
              imageUrl: movie.posterUrl,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(Icons.movie, size: 80),
              ),
            ),

            // Gradient Overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black26,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.4, 0.9],
                ),
              ),
            ),

            // Movie Information
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        movie.releaseYear,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: movie.genres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.overview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(MovieDiscoveryState state) {
    final bool hasMovies = state is MovieDiscoveryLoaded && _currentIndex < _currentMovies.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10, left: 24, right: 24),
      child: Column(
        children: [
          if (hasMovies)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Discard Button
                _buildRoundButton(
                  icon: Icons.close,
                  color: AppColors.error,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                ),
                // Play Trailer Button
                _buildRoundButton(
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.accent,
                  isLarge: true,
                  onTap: () {
                    final movie = _currentMovies[_currentIndex];
                    _playTrailer(movie.trailerYoutubeId);
                  },
                ),
                // Watchlist Button
                _buildRoundButton(
                  icon: Icons.favorite,
                  color: AppColors.primary,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                ),
              ],
            ),
          const SizedBox(height: 20),
          // AI Search bar trigger
          InkWell(
            onTap: _showMoodSheet,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hôm nay bạn muốn xem gì?',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final double size = isLarge ? 64 : 54;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: color, size: isLarge ? 32 : 24),
        ),
      ),
    );
  }
}
