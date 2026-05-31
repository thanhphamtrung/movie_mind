import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/watchlist_item.dart';

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

    final YoutubePlayerController playerController = YoutubePlayerController(
      initialVideoId: youtubeId,
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

  void _removeItem(String id) {
    setState(() {
      _mockWatchlist.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gỡ phim khỏi Watchlist'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh Sách Lưu'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ),
      body: _mockWatchlist.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
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
            color: Colors.black.withValues(alpha: 0.3),
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
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceElevated,
                child: const Icon(Icons.movie, size: 50),
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
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(4),
                    ),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _removeItem(item.id),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
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
                        color: Colors.white,
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
                        InkWell(
                          onTap: () => _playTrailer(item.trailerYoutubeId),
                          child: const Row(
                            children: [
                              Icon(Icons.play_circle_fill, color: AppColors.accent, size: 16),
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
