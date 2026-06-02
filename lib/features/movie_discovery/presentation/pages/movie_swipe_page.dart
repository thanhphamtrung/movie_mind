import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/movie.dart';
import '../bloc/movie_discovery_cubit.dart';
import '../bloc/movie_discovery_state.dart';
import '../widgets/filter_bottom_sheet.dart';

import 'package:go_router/go_router.dart';

class MovieSwipePage extends StatefulWidget {
  const MovieSwipePage({super.key});

  @override
  State<MovieSwipePage> createState() => _MovieSwipePageState();
}

class _MovieSwipePageState extends State<MovieSwipePage> {
  final CardSwiperController _swiperController = CardSwiperController();
  final TextEditingController _moodController = TextEditingController();
  int _currentIndex = 0;
  List<Movie> _currentMovies = [];

  final List<String> _quickMoods = [
    '🍿 Buổi tối ấm cúng',
    '🚀 Viễn tưởng kịch tính',
    '🤯 Hại não',
    '😂 Cười vỡ bụng',
  ];

  @override
  void dispose() {
    _swiperController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  void _resetDiscovery() {
    _moodController.clear();
    context.read<MovieDiscoveryCubit>().reset();
  }

  Future<void> _showFilterSheet() async {
    final result = await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (context) => const FilterBottomSheet(),
    );
    if (result != null && mounted) {
      context.read<MovieDiscoveryCubit>().generatePrompt(_moodController.text, result);
    }
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
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: const Text('Không thể mở liên kết YouTube!'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _playTrailer(String? youtubeId) {
    if (youtubeId == null || youtubeId.isEmpty) {
      _showErrorDialog('Không tìm thấy trailer cho phim này!');
      return;
    }

    final String parsedId = YoutubePlayer.convertUrlToId(youtubeId) ?? youtubeId;

    if (parsedId.length < 10 || parsedId.length > 12 || parsedId.contains(' ')) {
      _showErrorDialog('ID Trailer không khả dụng!');
      return;
    }

    final YoutubePlayerController playerController = YoutubePlayerController(
      initialVideoId: parsedId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.black,
            borderRadius: BorderRadius.circular(12),
          ),
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
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context.pop();
                        _launchYoutube(youtubeId);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.arrow_up_right_square, color: CupertinoColors.systemYellow, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Xem trên YouTube',
                            style: TextStyle(color: CupertinoColors.systemYellow, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                      child: const Text('Đóng', style: TextStyle(color: CupertinoColors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: BlocConsumer<MovieDiscoveryCubit, MovieDiscoveryState>(
        listener: (context, state) {
          if (state is MovieDiscoveryLoaded) {
            setState(() {
              _currentMovies = state.movies;
              _currentIndex = 0;
            });
          } else if (state is MovieDiscoveryPromptGenerated) {
            _moodController.text = state.newPrompt;
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
                          color: CupertinoColors.black.withValues(alpha: 0.65),
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
                          const SizedBox(width: 72), // Spacer for centering
                          Text(
                            'MovieMind',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [Color(0xFFFF7EB3), Color(0xFF8A2BE2)],
                                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _showFilterSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Row(
                                children: const [
                                  Icon(CupertinoIcons.slider_horizontal_3, size: 14, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('Filters', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Mood Prompt Pill
                    if (state is MovieDiscoveryLoaded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7EB3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '"${state.moodPrompt}"',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
    if (state is MovieDiscoveryInitial || state is MovieDiscoveryPromptGenerating || state is MovieDiscoveryPromptGenerated) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF7EB3).withValues(alpha: 0.3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF7EB3),
                    blurRadius: 20,
                  )
                ]
              ),
              child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFFF7EB3), size: 32),
            ),
            
            // Title
            const Text(
              'Hôm nay bạn cảm thấy thế nào?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            const Text(
              'Mô tả tâm trạng của bạn, AI sẽ gợi ý các bộ phim dành riêng cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 40),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _moodController,
                    maxLines: 3,
                    minLines: 3,
                    style: const TextStyle(fontSize: 15, color: CupertinoColors.white),
                    placeholder: state is MovieDiscoveryPromptGenerating 
                        ? 'AI đang tạo mô tả...' 
                        : 'VD: Tôi muốn xem một phim trinh thám hại não có kết thúc ấm áp...',
                    placeholderStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                    decoration: const BoxDecoration(color: CupertinoColors.transparent),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const Icon(CupertinoIcons.mic, color: AppColors.textMuted, size: 20),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7EB3), Color(0xFF8A2BE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Color(0x80FF7EB3), blurRadius: 15)
                          ]
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_moodController.text.trim().isNotEmpty) {
                              context.read<MovieDiscoveryCubit>().fetchMoviesForMood(_moodController.text.trim());
                            }
                          },
                          child: const Icon(CupertinoIcons.arrow_up, color: CupertinoColors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Suggestions
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GỢI Ý',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children: _quickMoods.map((mood) {
                return GestureDetector(
                  onTap: () {
                    _moodController.text = mood.substring(2).trim(); // Skip emoji
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mood.substring(0, 2), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(mood.substring(2).trim(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (state is MovieDiscoveryLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 16),
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
              const Icon(CupertinoIcons.exclamationmark_circle, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _resetDiscovery,
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
                const Icon(CupertinoIcons.check_mark_circled, size: 64, color: AppColors.success),
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
                CupertinoButton.filled(
                onPressed: _resetDiscovery,
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
        numberOfCardsDisplayed: 3,
        backCardOffset: const Offset(0, 30),
        scale: 0.9,
        onSwipe: (previousIndex, currentIndex, direction) {
          setState(() {
            _currentIndex = currentIndex ?? _currentIndex + 1;
          });
          if (direction == CardSwiperDirection.right) {
            // Save to Watchlist
            final savedMovie = _currentMovies[previousIndex];
            showCupertinoDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Đã lưu'),
                content: Text('Đã lưu "${savedMovie.title}" vào Watchlist'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Xem'),
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/watchlist');
                    },
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('Đóng'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
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
                child: CupertinoActivityIndicator(),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(CupertinoIcons.film, size: 80),
              ),
            ),

            // Dynamic Lighting Overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    CupertinoColors.black,
                    const Color(0xFF0B0E14).withValues(alpha: 0.6),
                    CupertinoColors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.black.withValues(alpha: 0.4),
                    CupertinoColors.transparent,
                    CupertinoColors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
            
            // Match Score Badge
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8A2BE2).withValues(alpha: 0.5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D8A2BE2),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.bolt_fill, color: Color(0xFFD8B4FE), size: 14),
                    SizedBox(width: 6),
                    Text(
                      '98% PHÙ HỢP',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Provider Badge
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'NETFLIX',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // AI HUD Analysis Panel
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x26FF7EB3), Color(0x268A2BE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7EB3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF7EB3).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(CupertinoIcons.wand_rays, color: Color(0xFFFF7EB3), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI PHÂN TÍCH _',
                            style: TextStyle(
                              color: Color(0xFFFF7EB3),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.reason.isNotEmpty 
                                ? movie.reason 
                                : 'Bộ phim này hoàn toàn khớp với tâm trạng của bạn dựa trên đánh giá sâu sắc về ${movie.genres.take(2).join(', ')}.',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Movie Details
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: CupertinoColors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        movie.releaseYear,
                        style: const TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(CupertinoIcons.circle_fill, size: 4, color: CupertinoColors.systemGrey),
                      ),
                      const Text(
                        '2h 14m',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(CupertinoIcons.circle_fill, size: 4, color: CupertinoColors.systemGrey),
                      ),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.star_fill, color: CupertinoColors.systemYellow, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres.map((genre) {
                      final isFirst = movie.genres.indexOf(genre) == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0x33FF7EB3) : CupertinoColors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFirst ? const Color(0x4DFF7EB3) : CupertinoColors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          genre.toUpperCase(),
                          style: TextStyle(
                            color: isFirst ? const Color(0xFFFF7EB3) : CupertinoColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
      padding: const EdgeInsets.only(bottom: 24, top: 12, left: 32, right: 32),
      child: Column(
        children: [
          if (hasMovies)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Discard Button
                _buildRoundButton(
                  icon: CupertinoIcons.clear,
                  color: AppColors.textMuted,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                  size: 64,
                ),
                // Play Trailer (Super Like / Play) Button
                _buildRoundButton(
                  icon: CupertinoIcons.play_arrow_solid,
                  color: const Color(0xFF8A2BE2),
                  onTap: () {
                    final movie = _currentMovies[_currentIndex];
                    _playTrailer(movie.trailerYoutubeId);
                  },
                  size: 48,
                ),
                // Watchlist (Like) Button
                _buildRoundButton(
                  icon: CupertinoIcons.heart_fill,
                  color: CupertinoColors.white,
                  onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                  size: 80,
                  isGradient: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
    bool isGradient = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isGradient ? null : CupertinoColors.white.withValues(alpha: 0.05),
        gradient: isGradient
            ? const LinearGradient(
                colors: [Color(0xFFFF7EB3), Color(0xFF8A2BE2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: isGradient ? CupertinoColors.white.withValues(alpha: 0.2) : CupertinoColors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          if (isGradient)
            const BoxShadow(
              color: Color(0x80FF7EB3),
              blurRadius: 40,
            )
          else
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
