import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ServerException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../models/movie_model.dart';

abstract class MovieRemoteDataSource {
  Future<List<MovieModel>> getRecommendations(String moodPrompt);
}

class MovieRemoteDataSourceImpl implements MovieRemoteDataSource {
  final GenerativeModel? _generativeModel;
  final Dio _dio;

  MovieRemoteDataSourceImpl({GenerativeModel? generativeModel, Dio? dio})
    : _generativeModel = generativeModel,
      _dio = dio ?? Dio();

  List<(MovieModel, String)> _cleanAndParseJson(String jsonString) {
    debugPrint('[MovieRemoteDataSourceImpl] Raw response text: $jsonString');
    String cleanJson = jsonString.trim();

    // Remove markdown code fences if present
    if (cleanJson.startsWith('```')) {
      final firstNewLine = cleanJson.indexOf('\n');
      if (firstNewLine != -1) {
        cleanJson = cleanJson.substring(firstNewLine + 1);
      } else {
        cleanJson = cleanJson.replaceAll('```', '');
      }

      final lastFences = cleanJson.lastIndexOf('```');
      if (lastFences != -1) {
        cleanJson = cleanJson.substring(0, lastFences);
      }
      cleanJson = cleanJson.trim();
    }

    // Always search for brackets in case there is extra text around the JSON array
    final startIdx = cleanJson.indexOf('[');
    final endIdx = cleanJson.lastIndexOf(']');
    if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
      cleanJson = cleanJson.substring(startIdx, endIdx + 1);
    }

    debugPrint('[MovieRemoteDataSourceImpl] Cleaned JSON to parse: $cleanJson');
    final decoded = jsonDecode(cleanJson);
    if (decoded is! List) {
      throw FormatException(
        'Expected a JSON list, but got: ${decoded.runtimeType}',
      );
    }

    final List<(MovieModel, String)> movies = [];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is Map<String, dynamic>) {
        final title = item['title']?.toString() ?? 'Phim không tên';
        final originalTitle = item['originalTitle']?.toString() ?? title;
        final overview =
            item['overview']?.toString() ?? 'Không có phần mô tả tóm tắt.';
        final rating = (item['rating'] as num?)?.toDouble() ?? 7.5;
        final releaseYear =
            item['releaseYear']?.toString() ?? DateTime.now().year.toString();

        final rawGenres = item['genres'];
        final List<String> genres = [];
        if (rawGenres is List) {
          genres.addAll(rawGenres.map((e) => e.toString()));
        } else {
          genres.add('AI Selection');
        }

        final trailerYoutubeId = item['trailerYoutubeId']?.toString();

        String posterUrl = item['posterUrl']?.toString() ?? '';
        if (posterUrl.contains('themoviedb.org') ||
            posterUrl.contains('tmdb.org')) {
          posterUrl = posterUrl
              .replaceAll('www.themoviedb.org', 'image.tmdb.org')
              .replaceAll('themoviedb.org', 'image.tmdb.org')
              .replaceAll('cf2.imgobject.com', 'image.tmdb.org');
        }

        if (posterUrl.isEmpty ||
            posterUrl == 'placeholder' ||
            !Uri.parse(posterUrl).isAbsolute) {
          posterUrl = _getFallbackPosterUrl(title);
        }

        final id =
            item['id']?.toString() ??
            'gemini-${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}-$i';

        movies.add((
          MovieModel(
            id: id,
            title: title,
            posterUrl: posterUrl,
            overview: overview,
            rating: rating,
            releaseYear: releaseYear,
            genres: genres,
            trailerYoutubeId: trailerYoutubeId,
          ),
          originalTitle,
        ));
      }
    }
    return movies;
  }

  String _getFallbackPosterUrl(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('space') ||
        lowerTitle.contains('star') ||
        lowerTitle.contains('interstellar') ||
        lowerTitle.contains('universe') ||
        lowerTitle.contains('sci-fi') ||
        lowerTitle.contains('viễn tưởng') ||
        lowerTitle.contains('vũ trụ')) {
      return 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=600&auto=format&fit=crop';
    } else if (lowerTitle.contains('shutter') ||
        lowerTitle.contains('island') ||
        lowerTitle.contains('detective') ||
        lowerTitle.contains('mystery') ||
        lowerTitle.contains('crime') ||
        lowerTitle.contains('mind') ||
        lowerTitle.contains('trinh thám') ||
        lowerTitle.contains('hình sự') ||
        lowerTitle.contains('kỳ bí')) {
      return 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=600&auto=format&fit=crop';
    } else if (lowerTitle.contains('hotel') ||
        lowerTitle.contains('grand') ||
        lowerTitle.contains('budapest') ||
        lowerTitle.contains('comedy') ||
        lowerTitle.contains('funny') ||
        lowerTitle.contains('guy') ||
        lowerTitle.contains('hangover') ||
        lowerTitle.contains('hài') ||
        lowerTitle.contains('vui nhộn')) {
      return 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?q=80&w=600&auto=format&fit=crop';
    } else if (lowerTitle.contains('love') ||
        lowerTitle.contains('romance') ||
        lowerTitle.contains('romantic') ||
        lowerTitle.contains('drama') ||
        lowerTitle.contains('sad') ||
        lowerTitle.contains('lãng mạn') ||
        lowerTitle.contains('tình cảm') ||
        lowerTitle.contains('chính kịch') ||
        lowerTitle.contains('buồn') ||
        lowerTitle.contains('mắt biếc')) {
      return 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?q=80&w=600&auto=format&fit=crop';
    } else {
      // Return a gorgeous cinematic film reel with colorful lights instead of dark empty theater seats
      return 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=600&auto=format&fit=crop';
    }
  }

  Future<bool> _isImageUrlValid(String url) async {
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      return false;
    }
    // Only bypass validation for direct Unsplash photo paths which are verified static assets
    if (url.contains('unsplash.com/photo-')) {
      return true;
    }
    try {
      // Use HEAD request to quickly check the resource existence without fetching the full body
      final response = await _dio
          .head(
            url,
            options: Options(
              followRedirects: true,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 300,
            ),
          )
          .timeout(const Duration(milliseconds: 1500));
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      // If HEAD request is blocked, returns 405 (Method Not Allowed), or throws, try a fast GET with range header
      try {
        final response = await _dio
            .get(
              url,
              options: Options(
                headers: {
                  'Range': 'bytes=0-0', // Just request the first byte
                },
                followRedirects: true,
                validateStatus: (status) =>
                    status != null && status >= 200 && status < 300,
              ),
            )
            .timeout(const Duration(milliseconds: 1500));
        return response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300;
      } catch (e) {
        debugPrint(
          '[MovieRemoteDataSourceImpl] Image check failed for url: $url, Error: $e',
        );
        return false;
      }
    }
  }

  Future<String?> _fetchPosterFromOphim(
    String title,
    String originalTitle,
  ) async {
    try {
      final searchQueries = [
        if (originalTitle.isNotEmpty && originalTitle != title) originalTitle,
        title,
      ];

      for (final query in searchQueries) {
        final encodedTitle = Uri.encodeComponent(query);
        final response = await _dio.get(
          'https://phimapi.com/v1/api/tim-kiem?keyword=$encodedTitle',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['status'] == 'success') {
            final nestedData = data['data'];
            if (nestedData is Map<String, dynamic>) {
              final items = nestedData['items'];
              final cdnImage =
                  nestedData['APP_DOMAIN_CDN_IMAGE']?.toString() ??
                  'https://img.ophim.live';
              if (items is List && items.isNotEmpty) {
                // Find the best match or take the first one
                for (var item in items) {
                  if (item is Map<String, dynamic>) {
                    final name = item['name']?.toString() ?? '';
                    final originName = item['origin_name']?.toString() ?? '';

                    // Simple match check
                    if (name.toLowerCase().contains(title.toLowerCase()) ||
                        title.toLowerCase().contains(name.toLowerCase()) ||
                        originName.toLowerCase().contains(
                          title.toLowerCase(),
                        )) {
                      final posterPath =
                          item['poster_url']?.toString() ??
                          item['thumb_url']?.toString() ??
                          '';
                      if (posterPath.isNotEmpty) {
                        if (posterPath.startsWith('http')) {
                          return posterPath;
                        }
                        return posterPath.startsWith('/') ? '$cdnImage$posterPath' : '$cdnImage/$posterPath';
                      }
                    }
                  }
                }

                // Fallback to the first item if no exact match but list is not empty
                final firstItem = items.first;
                if (firstItem is Map<String, dynamic>) {
                  final posterPath =
                      firstItem['poster_url']?.toString() ??
                      firstItem['thumb_url']?.toString() ??
                      '';
                  if (posterPath.isNotEmpty) {
                      if (posterPath.startsWith('http')) {
                        return posterPath;
                      }
                      return posterPath.startsWith('/') ? '$cdnImage$posterPath' : '$cdnImage/$posterPath';
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Error fetching poster from Ophim for "$title": $e',
      );
    }
    return null;
  }

  Future<String?> _fetchPosterFromTMDBScraper(String query) async {
    try {
      final encodedTitle = Uri.encodeComponent(query);
      final response = await _dio.get(
        'https://www.themoviedb.org/search?query=$encodedTitle',
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final regex = RegExp(
        r'src="https://media\.themoviedb\.org/t/p/[^/]+/([^"]+\.jpg)"',
      );
      final match = regex.firstMatch(response.data.toString());

      if (match != null) {
        final imageHash = match.group(1);
        if (imageHash != null && imageHash.isNotEmpty) {
          return 'https://media.themoviedb.org/t/p/w500/$imageHash';
        }
      }
    } catch (e) {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Error fetching poster from TMDB Scraper for "$query": $e',
      );
    }
    return null;
  }

  @override
  Future<List<MovieModel>> getRecommendations(String moodPrompt) async {
    if (_generativeModel != null) {
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (apiKey.isEmpty || apiKey == 'mock_key_here') {
          throw const FormatException(
            'Gemini API Key is empty or placeholder. Mock fallback will be used.',
          );
        }

        debugPrint(
          '[MovieRemoteDataSourceImpl] Requesting Gemini recommendations for mood: "$moodPrompt"',
        );
        final response = await _generativeModel.generateContent([
          Content.text(
            'Recommend 5 movies suitable for the mood: "$moodPrompt". '
            'Since the user is Vietnamese, all details ("title", "overview", and "genres") MUST be in Vietnamese. '
            'Provide a JSON array containing objects with:\n'
            '- id (unique string)\n'
            '- title (Vietnamese movie title, e.g. "Kẻ Cắp Giấc Mơ")\n'
            '- originalTitle (Original English or native movie title, e.g. "Inception")\n'
            '- posterUrl (valid URL string)\n'
            '- overview (Vietnamese summary of the movie)\n'
            '- rating (number from 1.0 to 10.0)\n'
            '- releaseYear (string, e.g. "2010")\n'
            '- genres (list of strings in Vietnamese, e.g., ["Hành Động", "Viễn Tưởng"])\n'
            '- trailerYoutubeId (optional string)\n\n'
            'Strict rules for "posterUrl":\n'
            '1. For very famous/popular movies (e.g. Inception, Interstellar, Coco, etc.), you can provide the exact, valid TMDB poster image URL (e.g., `https://image.tmdb.org/t/p/w500/edv5CZvX0jOKJsvSVgGEj7VjQ5L.jpg`).\n'
            '2. If you do not know the exact, real TMDB poster path (especially for local/Vietnamese movies or less popular ones), you MUST set "posterUrl" to the string "placeholder". Do NOT generate or guess TMDB or Unsplash search URLs because they will 404. Our app will automatically apply a premium movie-matched poster fallback for you.\n\n'
            'Ensure the JSON is strictly formatted and contains no additional commentary.',
          ),
        ]);

        final text = response.text;
        if (text != null && text.trim().isNotEmpty) {
          final movies = _cleanAndParseJson(text);
          if (movies.isNotEmpty) {
            debugPrint(
              '[MovieRemoteDataSourceImpl] Successfully parsed ${movies.length} movies from Gemini API. Verifying network availability of poster URLs...',
            );
            final verifiedMovies = await Future.wait(
              movies.map((record) async {
                final movie = record.$1;
                final originalTitle = record.$2;
                final isValid = await _isImageUrlValid(movie.posterUrl);
                if (isValid) {
                  return movie;
                } else {
                  debugPrint(
                    '[MovieRemoteDataSourceImpl] ⚠️ Image 404 or unreachable for "${movie.title}": ${movie.posterUrl}. Trying Ophim search lookup...',
                  );
                  final ophimPoster = await _fetchPosterFromOphim(
                    movie.title,
                    originalTitle,
                  );
                  if (ophimPoster != null) {
                    final isOphimValid = await _isImageUrlValid(ophimPoster);
                    if (isOphimValid) {
                      debugPrint(
                        '[MovieRemoteDataSourceImpl] 🌟 Successfully retrieved real poster from Ophim for "${movie.title}": $ophimPoster',
                      );
                      return movie.copyWith(posterUrl: ophimPoster);
                    }
                  }

                  debugPrint(
                    '[MovieRemoteDataSourceImpl] ⚠️ Ophim poster lookup failed for "${movie.title}". Trying TMDB Scraper...',
                  );

                  String? tmdbPoster;
                  final queries = [
                    if (originalTitle.isNotEmpty && originalTitle != movie.title)
                      originalTitle,
                    movie.title,
                  ];
                  
                  for (final q in queries) {
                    final fetched = await _fetchPosterFromTMDBScraper(q);
                    if (fetched != null) {
                      final isValid = await _isImageUrlValid(fetched);
                      if (isValid) {
                        tmdbPoster = fetched;
                        break;
                      }
                    }
                  }

                  if (tmdbPoster != null) {
                    debugPrint(
                      '[MovieRemoteDataSourceImpl] 🌟 Successfully retrieved real poster from TMDB Scraper for "${movie.title}": $tmdbPoster',
                    );
                    return movie.copyWith(posterUrl: tmdbPoster);
                  }

                  debugPrint(
                    '[MovieRemoteDataSourceImpl] ⚠️ TMDB Scraper failed/invalid for "${movie.title}". Applying premium Unsplash fallback.',
                  );
                  return movie.copyWith(
                    posterUrl: _getFallbackPosterUrl(movie.title),
                  );
                }
              }),
            );
            debugPrint(
              '[MovieRemoteDataSourceImpl] Finished verifying poster URLs. Returning ${verifiedMovies.length} movies.',
            );
            return verifiedMovies;
          }
        } else {
          throw const FormatException(
            'Empty text response received from Gemini.',
          );
        }
      } catch (e, stackTrace) {
        debugPrint(
          '[MovieRemoteDataSourceImpl] ⚠️ ERROR occurred during Gemini API fetch/parse:',
        );
        debugPrint('Error details: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint(
          '[MovieRemoteDataSourceImpl] Gracefully falling back to premium local cinematic database.',
        );
      }
    } else {
      debugPrint(
        '[MovieRemoteDataSourceImpl] No GenerativeModel configured. Loading local cinema database.',
      );
    }

    // High-quality cinema mock database providing a premium instant experience
    await Future.delayed(const Duration(seconds: 2));

    final query = moodPrompt.toLowerCase();
    if (query.contains('buồn') ||
        query.contains('sad') ||
        query.contains('khóc')) {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Mood identified: SAD. Returning curated local selection.',
      );
      return _sadMoodMovies;
    } else if (query.contains('trinh thám') ||
        query.contains('hack não') ||
        query.contains('mystery') ||
        query.contains('mind')) {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Mood identified: MYSTERY. Returning curated local selection.',
      );
      return _mysteryMoodMovies;
    } else if (query.contains('hài') ||
        query.contains('funny') ||
        query.contains('cười')) {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Mood identified: COMEDY. Returning curated local selection.',
      );
      return _comedyMoodMovies;
    } else {
      debugPrint(
        '[MovieRemoteDataSourceImpl] Mood identified: GENERAL. Returning curated local selection.',
      );
      return _generalMovies;
    }
  }

  // Pre-configured premium cinematic collections
  static const List<MovieModel> _mysteryMoodMovies = [
    MovieModel(
      id: 'm1',
      title: 'Knives Out',
      posterUrl:
          'https://images.unsplash.com/photo-1594909122845-11baa439b7bf?q=80&w=600&auto=format&fit=crop',
      overview:
          'Khi thám tử lừng danh Benoit Blanc bất ngờ được thuê để điều tra cái chết bí ẩn của tiểu thuyết gia trinh thám nổi tiếng Harlan Thrombey, mọi thành viên trong gia đình lập dị đều trở thành kẻ tình nghi.',
      rating: 7.9,
      releaseYear: '2019',
      genres: ['Mystery', 'Comedy', 'Drama'],
      trailerYoutubeId: 'qGqiHJTsRkQ',
    ),
    MovieModel(
      id: 'm2',
      title: 'Shutter Island',
      posterUrl:
          'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=600&auto=format&fit=crop',
      overview:
          'Vào năm 1954, một đặc vụ liên bang Mỹ điều tra sự biến mất của một sát thủ trốn thoát khỏi bệnh viện tâm thần trên đảo Shutter hẻo lánh.',
      rating: 8.2,
      releaseYear: '2010',
      genres: ['Mystery', 'Thriller'],
      trailerYoutubeId: '5iaYLCip5vg',
    ),
    MovieModel(
      id: 'm3',
      title: 'Interstellar',
      posterUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=600&auto=format&fit=crop',
      overview:
          'Một nhóm các nhà thám hiểm du hành qua một hố đen ngoài vũ trụ để tìm kiếm sự sống còn của nhân loại trên các hành tinh mới.',
      rating: 8.7,
      releaseYear: '2014',
      genres: ['Sci-Fi', 'Adventure', 'Drama'],
      trailerYoutubeId: 'zSWdZVtXT7E',
    ),
  ];

  static const List<MovieModel> _sadMoodMovies = [
    MovieModel(
      id: 's1',
      title: 'The Pursuit of Happyness',
      posterUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?q=80&w=600&auto=format&fit=crop',
      overview:
          'Câu chuyện lay động lòng người về nỗ lực phi thường của Chris Gardner vượt qua nghịch cảnh vô gia cư để mang lại cuộc sống hạnh phúc cho con trai mình.',
      rating: 8.0,
      releaseYear: '2006',
      genres: ['Drama', 'Biography'],
      trailerYoutubeId: 'DMOBlEcRuw8',
    ),
    MovieModel(
      id: 's2',
      title: 'Coco',
      posterUrl:
          'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?q=80&w=600&auto=format&fit=crop',
      overview:
          'Cậu bé Miguel nuôi ước mơ âm nhạc cháy bỏng bước vào Vùng Đất Linh Hồn rực rỡ để giải mã bí mật gia tộc lâu đời.',
      rating: 8.4,
      releaseYear: '2017',
      genres: ['Animation', 'Family', 'Fantasy'],
      trailerYoutubeId: 'Rvr68u6k5sI',
    ),
  ];

  static const List<MovieModel> _comedyMoodMovies = [
    MovieModel(
      id: 'c1',
      title: 'Free Guy',
      posterUrl:
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop',
      overview:
          'Một nhân viên giao dịch ngân hàng phát hiện ra mình thực chất là một NPC nền trong trò chơi điện tử thế giới mở tàn bạo.',
      rating: 7.1,
      releaseYear: '2021',
      genres: ['Action', 'Comedy', 'Sci-Fi'],
      trailerYoutubeId: 'X2m-08c37fc',
    ),
    MovieModel(
      id: 'c2',
      title: 'The Grand Budapest Hotel',
      posterUrl:
          'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=600&auto=format&fit=crop',
      overview:
          'Cuộc phiêu lưu đầy hài hước và nghệ thuật của người quản lý khách sạn huyền thoại Gustave H và người hầu phòng Zero Moustafa.',
      rating: 8.1,
      releaseYear: '2014',
      genres: ['Comedy', 'Drama'],
      trailerYoutubeId: '1Fg5iWmQjwk',
    ),
  ];

  static const List<MovieModel> _generalMovies = [
    MovieModel(
      id: 'g1',
      title: 'Inception',
      posterUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=600&auto=format&fit=crop',
      overview:
          'Một kẻ trộm chuyên nghiệp có khả năng xâm nhập vào giấc mơ của người khác để đánh cắp bí mật kinh doanh phải thực hiện một nhiệm vụ bất khả thi: gieo mầm một ý tưởng.',
      rating: 8.8,
      releaseYear: '2010',
      genres: ['Action', 'Sci-Fi', 'Adventure'],
      trailerYoutubeId: 'YoHD9XEInc0',
    ),
    MovieModel(
      id: 'g2',
      title: 'Spirited Away',
      posterUrl:
          'https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=600&auto=format&fit=crop',
      overview:
          'Cô bé Chihiro lạc vào một thế giới phép thuật kỳ lạ do các vị thần cai trị và nỗ lực hết mình để giải cứu cha mẹ mình.',
      rating: 8.6,
      releaseYear: '2001',
      genres: ['Animation', 'Adventure', 'Fantasy'],
      trailerYoutubeId: 'ByXuk9QqQkk',
    ),
  ];
}
