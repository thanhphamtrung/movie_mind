import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/watchlist_item.dart';

abstract class WatchlistRepository {
  Future<Result<List<WatchlistItem>, Failure>> getWatchlist();
  Future<Result<void, Failure>> saveToWatchlist(WatchlistItem item);
  Future<Result<void, Failure>> removeFromWatchlist(String id);
}
