import 'package:flutter/cupertino.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/watchlist_item.dart';
import 'package:go_router/go_router.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  // Mock local watchlist database for dynamic premium mock features
  final List<WatchlistItem> _mockWatchlist = [
    WatchlistItem(
      id: 'm1',
      title: 'Knives Out',
      posterUrl: 'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?q=80&w=600&auto=format&fit=crop',
      rating: 7.9,
      releaseYear: '2019',
      trailerYoutubeId: 'qGqiHJTsRkQ',
      savedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    WatchlistItem(
      id: 'g1',
      title: 'Inception',
      posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=600&auto=format&fit=crop',
      rating: 8.8,
      releaseYear: '2010',
      trailerYoutubeId: 'YoHD9XEInc0',
      savedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

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
                )
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

    final YoutubePlayerController playerController = YoutubePlayerController(
      initialVideoId: youtubeId,
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

  void _removeItem(String id) {
    setState(() {
      _mockWatchlist.removeWhere((item) => item.id == id);
    });
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Thành công'),
        content: const Text('Đã gỡ phim khỏi Watchlist'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Danh Sách Lưu', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: _mockWatchlist.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.bookmark,
                        size: 72,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Watchlist Trống',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vuốt phải trên các thẻ phim gợi ý để lưu lại những tác phẩm yêu thích tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _mockWatchlist.length,
              itemBuilder: (context, index) {
                final item = _mockWatchlist[index];
                return _buildWatchlistCard(item);
              },
            ),
      ),
    );
  }

  Widget _buildWatchlistCard(WatchlistItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Movie Poster image with cached_network_image
            CachedNetworkImage(
              imageUrl: item.posterUrl,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
              placeholder: (context, url) => const Center(
                child: CupertinoActivityIndicator(),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceElevated,
                child: const Icon(CupertinoIcons.film, size: 50),
              ),
            ),

            // Top overlay bar with rating & delete button
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, color: CupertinoColors.systemYellow, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _removeItem(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.54),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.delete, color: AppColors.error, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom title overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [CupertinoColors.transparent, CupertinoColors.black.withValues(alpha: 0.87)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.releaseYear,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => _playTrailer(item.trailerYoutubeId),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.play_circle_fill, color: AppColors.accent, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Trailer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
