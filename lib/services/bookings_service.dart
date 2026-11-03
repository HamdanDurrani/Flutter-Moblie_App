import '../models/booking.dart';
import 'api_client.dart';

class BookingsService {
  BookingsService(this._api);

  final ApiClient _api;

  Future<BookingListResult> listBookings({
    required String segment,
    String? q,
    String? dateFrom,
    String? dateTo,
    String? eventType,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, String>{
      'segment': segment,
      'page': '$page',
      'pageSize': '$pageSize',
    };
    final trimmedQ = q?.trim();
    if (trimmedQ != null && trimmedQ.isNotEmpty) query['q'] = trimmedQ;
    if (dateFrom != null && dateFrom.isNotEmpty) query['dateFrom'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) query['dateTo'] = dateTo;
    if (eventType != null &&
        eventType.isNotEmpty &&
        eventType != 'all') {
      query['eventType'] = eventType;
    }

    final qs = query.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/bookings?$qs',
    );

    final sectionsRaw = data['sections'];
    final sections = <BookingSection>[];
    if (sectionsRaw is List) {
      for (final s in sectionsRaw) {
        if (s is! Map<String, dynamic>) continue;
        final bookingsRaw = s['bookings'];
        sections.add(
          BookingSection(
            date: '${s['date'] ?? ''}',
            title: '${s['title'] ?? ''}',
            bookings: bookingsRaw is List
                ? bookingsRaw
                    .whereType<Map<String, dynamic>>()
                    .map(Booking.fromApi)
                    .toList()
                : const [],
          ),
        );
      }
    }

    final hasMore = data['has_more'] is bool
        ? data['has_more'] as bool
        : (data['has_next'] == true);

    return BookingListResult(
      segment: '${data['segment'] ?? segment}',
      sections: sections,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['page_size'] as num?)?.toInt() ?? pageSize,
      total: (data['total'] as num?)?.toInt() ?? 0,
      hasMore: hasMore,
    );
  }

  Future<Booking> getBooking(String id) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/bookings/$id',
    );
    return Booking.fromApi(data);
  }

  Future<PaymentProgress> fetchPaymentProgress(String id) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/bookings/$id/payment-progress',
    );
    return PaymentProgress.fromApi(data);
  }

  Future<Booking> updatePackage(String id, double totalAmount) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/bookings/$id',
      method: 'PATCH',
      body: {'totalAmount': totalAmount},
      fallbackError: 'Could not update package amount.',
    );
    return Booking.fromApi(data);
  }

  Future<Booking> addPayment(
    String id, {
    required double amount,
    required String method,
    String? label,
    String? note,
  }) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/bookings/$id/payments',
      method: 'POST',
      body: {
        'amount': amount,
        'method': method,
        'label': ?label,
        'note': ?note,
      },
      fallbackError: 'Could not record payment.',
    );
    return Booking.fromApi(data);
  }
}
