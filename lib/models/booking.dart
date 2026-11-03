class BookingPayment {
  const BookingPayment({
    required this.id,
    required this.label,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.note,
    this.recordedByName,
    this.recordedByRole,
  });

  final String id;
  final String label;
  final double amount;
  final String method;
  final String paidAt;
  final String? note;
  final String? recordedByName;
  final String? recordedByRole;

  factory BookingPayment.fromApi(Map<String, dynamic> row) {
    return BookingPayment(
      id: '${row['id']}',
      label: '${row['label'] ?? ''}',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      method: '${row['method'] ?? ''}',
      paidAt: '${row['paid_at'] ?? ''}',
      note: row['note'] as String?,
      recordedByName: row['recorded_by_name'] as String?,
      recordedByRole: row['recorded_by_role'] as String?,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.enquiryId,
    required this.reservationNumber,
    required this.guestName,
    required this.phone,
    required this.email,
    required this.eventType,
    required this.eventDate,
    required this.shiftLabel,
    required this.startHour,
    required this.endHour,
    required this.liveKind,
    required this.liveLabel,
    required this.stageRequired,
    required this.totalAmount,
    required this.paidTotal,
    required this.balanceDue,
    required this.paidPercent,
    this.guestCount,
    this.guestRangeLabel,
    this.shift,
    this.stageImageUrl,
    this.acceptedByName,
    this.acceptedByRole,
    this.payments = const [],
  });

  final String id;
  final String enquiryId;
  final String reservationNumber;
  final String guestName;
  final String phone;
  final String email;
  final String eventType;
  final int? guestCount;
  final String? guestRangeLabel;
  final String eventDate;
  final String? shift;
  final String shiftLabel;
  final int startHour;
  final int endHour;
  final String liveKind;
  final String liveLabel;
  final bool stageRequired;
  final String? stageImageUrl;
  final double totalAmount;
  final double paidTotal;
  final double balanceDue;
  final double paidPercent;
  final String? acceptedByName;
  final String? acceptedByRole;
  final List<BookingPayment> payments;

  factory Booking.fromApi(Map<String, dynamic> row) {
    final paymentsRaw = row['payments'];
    return Booking(
      id: '${row['id']}',
      enquiryId: '${row['enquiry_id'] ?? ''}',
      reservationNumber: '${row['reservation_number'] ?? ''}',
      guestName: '${row['guest_name'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      email: '${row['email'] ?? ''}',
      eventType: '${row['event_type'] ?? ''}',
      guestCount: (row['guest_count'] as num?)?.toInt(),
      guestRangeLabel: row['guest_range_label'] as String?,
      eventDate: '${row['event_date'] ?? ''}',
      shift: row['shift'] as String?,
      shiftLabel: '${row['shift_label'] ?? ''}',
      startHour: (row['start_hour'] as num?)?.toInt() ?? 0,
      endHour: (row['end_hour'] as num?)?.toInt() ?? 0,
      liveKind: '${row['live_kind'] ?? 'upcoming'}',
      liveLabel: '${row['live_label'] ?? ''}',
      stageRequired: row['stage_required'] == true,
      stageImageUrl: row['stage_image_url'] as String?,
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
      paidTotal: (row['paid_total'] as num?)?.toDouble() ?? 0,
      balanceDue: (row['balance_due'] as num?)?.toDouble() ?? 0,
      paidPercent: (row['paid_percent'] as num?)?.toDouble() ?? 0,
      acceptedByName: row['accepted_by_name'] as String?,
      acceptedByRole: row['accepted_by_role'] as String?,
      payments: paymentsRaw is List
          ? paymentsRaw
              .whereType<Map<String, dynamic>>()
              .map(BookingPayment.fromApi)
              .toList()
          : const [],
    );
  }
}

class BookingSection {
  const BookingSection({
    required this.date,
    required this.title,
    required this.bookings,
  });

  final String date;
  final String title;
  final List<Booking> bookings;
}

class BookingListResult {
  const BookingListResult({
    required this.segment,
    required this.sections,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final String segment;
  final List<BookingSection> sections;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
}

class PaymentProgress {
  const PaymentProgress({
    required this.bookingId,
    required this.reservationNumber,
    required this.guestName,
    required this.eventType,
    required this.eventDate,
    required this.shiftLabel,
    required this.totalAmount,
    required this.paidTotal,
    required this.balanceDue,
    required this.paidPercent,
    required this.status,
    required this.statusLabel,
    required this.canEditPackage,
    required this.canEditPayments,
    this.payments = const [],
  });

  final String bookingId;
  final String reservationNumber;
  final String guestName;
  final String eventType;
  final String eventDate;
  final String shiftLabel;
  final double totalAmount;
  final double paidTotal;
  final double balanceDue;
  final double paidPercent;
  final String status;
  final String statusLabel;
  final bool canEditPackage;
  final bool canEditPayments;
  final List<BookingPayment> payments;

  factory PaymentProgress.fromApi(Map<String, dynamic> row) {
    final paymentsRaw = row['payments'];
    return PaymentProgress(
      bookingId: '${row['booking_id']}',
      reservationNumber: '${row['reservation_number'] ?? ''}',
      guestName: '${row['guest_name'] ?? ''}',
      eventType: '${row['event_type'] ?? ''}',
      eventDate: '${row['event_date'] ?? ''}',
      shiftLabel: '${row['shift_label'] ?? ''}',
      totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0,
      paidTotal: (row['paid_total'] as num?)?.toDouble() ?? 0,
      balanceDue: (row['balance_due'] as num?)?.toDouble() ?? 0,
      paidPercent: (row['paid_percent'] as num?)?.toDouble() ?? 0,
      status: '${row['status'] ?? 'unset'}',
      statusLabel: '${row['status_label'] ?? ''}',
      canEditPackage: row['can_edit_package'] != false,
      canEditPayments: row['can_edit_payments'] != false,
      payments: paymentsRaw is List
          ? paymentsRaw
              .whereType<Map<String, dynamic>>()
              .map(BookingPayment.fromApi)
              .toList()
          : const [],
    );
  }
}

String formatMoney(num amount) {
  final n = amount.round();
  final s = n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'Rs $s';
}

String formatHour(int h) {
  if (h >= 24) return '12am';
  final suffix = h >= 12 ? 'pm' : 'am';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12$suffix';
}

String eventThumbAsset(String eventType) {
  const map = {
    'Wedding': 'assets/images/events/wedding.jpg',
    'Walima': 'assets/images/events/walima.jpg',
    'Engagement': 'assets/images/events/engagement.jpg',
    'Mehndi': 'assets/images/events/mehndi.jpg',
    'Corporate': 'assets/images/events/corporate.jpg',
    'Nikah': 'assets/images/events/nikah.jpg',
    'Private Celebration': 'assets/images/events/private-celebration.jpg',
  };
  return map[eventType] ?? map['Wedding']!;
}

List<BookingSection> mergeBookingSections(
  List<BookingSection> existing,
  List<BookingSection> incoming,
) {
  if (incoming.isEmpty) return existing;
  if (existing.isEmpty) return incoming;

  final next = existing
      .map(
        (s) => BookingSection(
          date: s.date,
          title: s.title,
          bookings: List<Booking>.from(s.bookings),
        ),
      )
      .toList();
  final seen = <String>{
    for (final s in next)
      for (final b in s.bookings) b.id,
  };

  for (final section in incoming) {
    final fresh = section.bookings.where((b) {
      if (seen.contains(b.id)) return false;
      seen.add(b.id);
      return true;
    }).toList();
    if (fresh.isEmpty) continue;

    if (next.isNotEmpty && next.last.date == section.date) {
      next[next.length - 1] = BookingSection(
        date: next.last.date,
        title: next.last.title,
        bookings: [...next.last.bookings, ...fresh],
      );
    } else {
      next.add(
        BookingSection(
          date: section.date,
          title: section.title,
          bookings: fresh,
        ),
      );
    }
  }
  return next;
}
