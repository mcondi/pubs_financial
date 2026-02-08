import 'package:dio/dio.dart';
import 'stock_models.dart';

class StockRepository {
  final Dio _dio;
  StockRepository(this._dio);

  /// Base call (single date). Use only when you already know the weekendDate exists.
  Future<StockSummary> getSummary({
    required int venueId,
    required DateTime weekendDate,
    String mode = 'weekly',
  }) async {
    final res = await _dio.get(
      '/api/stock/summary',
      queryParameters: {
        'venueId': venueId,
        'weekendDate': _ymd(weekendDate),
        'mode': mode,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );

    return StockSummary.fromJson(res.data as Map<String, dynamic>);
  }

  /// ✅ Recommended: get the latest available week by stepping back week-by-week.
  /// This prevents the "404 because weekendDate doesn't exist" problem.
  Future<StockSummary> getSummaryLatest({
    required int venueId,
    String mode = 'weekly',
    int maxWeeksBack = 104, // 2 years
  }) async {
    return getSummaryWithFallback(
      venueId: venueId,
      startWeekendDate: DateTime.now(),
      mode: mode,
      maxWeeksBack: maxWeeksBack,
    );
  }

  /// Tries startWeekendDate aligned to Sunday, then -7d, -14d... until it finds data.
  /// 404 means "no row for that date" so we keep stepping back.
  Future<StockSummary> getSummaryWithFallback({
    required int venueId,
    required DateTime startWeekendDate,
    String mode = 'weekly',
    int maxWeeksBack = 104, // default 2 years
  }) async {
    DateTime d = _lastSunday(startWeekendDate);
    DioException? last404;

    for (var i = 0; i <= maxWeeksBack; i++) {
      // Helpful logging while you’re getting this working. Remove later if you want.
      // ignore: avoid_print
      print('StockSummary try venueId=$venueId date=${_ymd(d)} mode=$mode');

      try {
        return await getSummary(
          venueId: venueId,
          weekendDate: d,
          mode: mode,
        );
      } on DioException catch (e) {
        final code = e.response?.statusCode;

        // 404 = no row for that date/venue -> step back one week
        if (code == 404) {
          last404 = e;
          d = d.subtract(const Duration(days: 7));
          continue;
        }

        // Anything else should bubble up (401, 500, etc)
        rethrow;
      }
    }

    throw DioException(
      requestOptions: last404?.requestOptions ?? RequestOptions(path: '/api/stock/summary'),
      response: last404?.response,
      type: DioExceptionType.badResponse,
      error: 'No stock data found for venueId=$venueId in the last $maxWeeksBack weeks.',
    );
  }

  static String _ymd(DateTime d) => d.toIso8601String().substring(0, 10);

  static DateTime _lastSunday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final daysSinceSunday = now.weekday % 7; // Sunday=0
    return d.subtract(Duration(days: daysSinceSunday));
  }
}
