import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/bookings_service.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/booking_card.dart';
import 'booking_detail_screen.dart';

enum UiSegment { booked, pending, history }

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, required this.colors});

  final ThemeColors colors;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static const _pageSize = 10;

  UiSegment _segment = UiSegment.booked;
  List<BookingSection> _sections = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _hasMore = false;
  int _page = 1;
  int _total = 0;
  String? _error;
  bool _loadingMoreGuard = false;

  ThemeColors get c => widget.colors;

  String? _apiSegment(UiSegment ui) {
    switch (ui) {
      case UiSegment.booked:
        return 'upcoming';
      case UiSegment.pending:
        return 'pending';
      case UiSegment.history:
        return 'ended';
    }
  }

  BookingsService get _service =>
      BookingsService(context.read<AuthState>().api);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(replace: true));
  }

  Future<void> _load({bool replace = true, bool silent = false}) async {
    final api = _apiSegment(_segment);
    if (api == null) return;

    final nextPage = replace ? 1 : _page + 1;
    if (!replace) {
      if (_loadingMoreGuard || !_hasMore) return;
      _loadingMoreGuard = true;
      setState(() => _loadingMore = true);
    } else {
      _loadingMoreGuard = false;
      if (!silent) setState(() => _loading = true);
    }

    setState(() => _error = null);

    try {
      final data = await _service.listBookings(
        segment: api,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _page = data.page;
        _total = data.total;
        _hasMore = data.hasMore;
        _sections = replace
            ? data.sections
            : mergeBookingSections(_sections, data.sections);
      });
    } on ApiError catch (err) {
      if (!mounted) return;
      setState(() {
        if (replace) {
          _sections = [];
          _total = 0;
          _hasMore = false;
        }
        _error = err.detail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (replace) {
          _sections = [];
          _total = 0;
          _hasMore = false;
        }
        _error = 'Could not load bookings from the server.';
      });
    } finally {
      _loadingMoreGuard = false;
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _refreshing = false;
        });
      }
    }
  }

  void _changeSegment(UiSegment next) {
    if (next == _segment) return;
    setState(() {
      _segment = next;
      _sections = [];
      _page = 1;
      _hasMore = false;
      _error = null;
    });
    _load(replace: true);
  }

  Future<void> _openBooking(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          colors: c,
          bookingId: booking.id,
        ),
      ),
    );
    if (mounted) _load(replace: true, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    final showPending = user?.canViewPayments ?? false;
    final segments = [
      (UiSegment.booked, 'Booked'),
      if (showPending) (UiSegment.pending, 'Pending'),
      (UiSegment.history, 'History'),
    ];

    if (!showPending && _segment == UiSegment.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changeSegment(UiSegment.booked);
      });
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bookings',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                        if (user != null)
                          Text(
                            user.name,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => auth.logout(),
                    icon: Icon(Icons.logout, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in segments)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.$2),
                        selected: _segment == entry.$1,
                        onSelected: (_) => _changeSegment(entry.$1),
                        selectedColor: c.champagne,
                        backgroundColor: c.surface,
                        labelStyle: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          color: _segment == entry.$1
                              ? c.textOnAccent
                              : c.textSecondary,
                        ),
                        side: BorderSide(color: c.border),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
            ),
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  '$_total booking${_total == 1 ? '' : 's'}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: c.textMuted,
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: c.champagne,
                onRefresh: () async {
                  setState(() => _refreshing = true);
                  await _load(replace: true, silent: true);
                },
                child: _buildBody(showPending),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool showPayments) {
    if (_loading && _sections.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: c.champagne)),
        ],
      );
    }

    if (_error != null && _sections.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: c.danger, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _load(replace: true),
              child: Text(
                'Retry',
                style: GoogleFonts.outfit(
                  color: c.champagne,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_sections.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Text(
            'No bookings in this list.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: c.textMuted, fontSize: 15),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _load(replace: false);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _sections.length + (_loadingMore || _refreshing ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _sections.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: c.champagne),
              ),
            );
          }
          final section = _sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 8),
                child: Text(
                  section.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ),
              for (final booking in section.bookings) ...[
                BookingCard(
                  item: booking,
                  colors: c,
                  showPayments: showPayments,
                  pendingMode: _segment == UiSegment.pending,
                  onTap: () => _openBooking(booking),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
