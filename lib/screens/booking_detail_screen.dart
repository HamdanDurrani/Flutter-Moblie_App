import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';
import '../services/api_client.dart';
import '../services/bookings_service.dart';
import '../state/auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/booking_card.dart';
import '../widgets/pc_button.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.colors,
    required this.bookingId,
  });

  final ThemeColors colors;
  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  PaymentProgress? _progress;
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0 details, 1 payments

  final _payAmount = TextEditingController();
  final _packageAmount = TextEditingController();
  String _payMethod = 'cash';
  String _payLabel = '1st installment';
  bool _savingPay = false;
  bool _savingPackage = false;

  ThemeColors get c => widget.colors;

  BookingsService get _service =>
      BookingsService(context.read<AuthState>().api);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _payAmount.dispose();
    _packageAmount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await _service.getBooking(widget.bookingId);
      PaymentProgress? progress;
      try {
        progress = await _service.fetchPaymentProgress(widget.bookingId);
      } catch (_) {
        progress = null;
      }
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _progress = progress;
        _packageAmount.text = booking.totalAmount > 0
            ? booking.totalAmount.round().toString()
            : '';
        _loading = false;
      });
    } on ApiError catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load booking.';
        _loading = false;
      });
    }
  }

  String _friendlyDate(String ymd) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _savePackage() async {
    final amount = double.tryParse(_packageAmount.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid package amount.')),
      );
      return;
    }
    setState(() => _savingPackage = true);
    try {
      final booking = await _service.updatePackage(widget.bookingId, amount);
      final progress = await _service.fetchPaymentProgress(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _progress = progress;
      });
    } on ApiError catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.detail)));
    } finally {
      if (mounted) setState(() => _savingPackage = false);
    }
  }

  Future<void> _addPayment() async {
    final amount = double.tryParse(_payAmount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a payment amount.')),
      );
      return;
    }
    setState(() => _savingPay = true);
    try {
      final booking = await _service.addPayment(
        widget.bookingId,
        amount: amount,
        method: _payMethod,
        label: _payLabel,
      );
      final progress = await _service.fetchPaymentProgress(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _progress = progress;
        _payAmount.clear();
      });
    } on ApiError catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.detail)));
    } finally {
      if (mounted) setState(() => _savingPay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final canPay = auth.user?.canViewPayments ?? false;
    final canManage = auth.user?.canManageBookings ?? false;
    final canContact = auth.user?.canViewGuestContact ?? false;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(
          _booking?.reservationNumber ?? 'Booking',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.champagne))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: c.danger),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: Text(
                            'Retry',
                            style: GoogleFonts.outfit(color: c.champagne),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(canPay, canManage, canContact),
    );
  }

  Widget _buildContent(bool canPay, bool canManage, bool canContact) {
    final b = _booking!;
    final thumb = b.stageImageUrl != null && b.stageImageUrl!.isNotEmpty
        ? NetworkImage(b.stageImageUrl!)
        : AssetImage(eventThumbAsset(b.eventType)) as ImageProvider;

    return Column(
      children: [
        if (canPay)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _tabChip('Details', 0)),
                const SizedBox(width: 8),
                Expanded(child: _tabChip('Payments', 1)),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: Image(
                  image: thumb,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              StatusChip(
                kind: b.liveKind,
                label: b.liveLabel,
                colors: c,
              ),
              const SizedBox(height: 10),
              Text(
                b.guestName,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${b.eventType} · ${_friendlyDate(b.eventDate)} · ${b.shiftLabel}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatHour(b.startHour)} – ${formatHour(b.endHour)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              if (_tab == 0 || !canPay) ..._details(b, canContact),
              if (_tab == 1 && canPay) ..._payments(b, canManage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tab == index;
    return ChoiceChip(
      label: Center(child: Text(label)),
      selected: selected,
      onSelected: (_) => setState(() => _tab = index),
      selectedColor: c.champagne,
      backgroundColor: c.surface,
      labelStyle: GoogleFonts.outfit(
        fontWeight: FontWeight.w500,
        color: selected ? c.textOnAccent : c.textSecondary,
      ),
      side: BorderSide(color: c.border),
      showCheckmark: false,
    );
  }

  List<Widget> _details(Booking b, bool canContact) {
    return [
      _infoCard([
        _kv('Reservation', b.reservationNumber),
        _kv(
          'Guests',
          b.guestCount != null
              ? '${b.guestCount}'
              : (b.guestRangeLabel ?? '—'),
        ),
        _kv('Stage', b.stageRequired ? 'Required' : 'Not required'),
        _kv('Accepted by', b.acceptedByName ?? 'Office'),
      ]),
      if (canContact) ...[
        const SizedBox(height: 12),
        _infoCard([
          _kv('Phone', b.phone.isEmpty ? '—' : b.phone),
          _kv('Email', b.email.isEmpty ? '—' : b.email),
        ]),
        if (b.phone.isNotEmpty) ...[
          const SizedBox(height: 12),
          PcButton(
            label: 'Call guest',
            colors: c,
            variant: PcButtonVariant.secondary,
            onPressed: () => _call(b.phone),
          ),
        ],
      ],
      const SizedBox(height: 12),
      _infoCard([
        _kv('Package', formatMoney(b.totalAmount)),
        _kv('Paid', formatMoney(b.paidTotal)),
        _kv(
          'Balance',
          b.balanceDue > 0 ? formatMoney(b.balanceDue) : 'Fully paid',
        ),
      ]),
    ];
  }

  List<Widget> _payments(Booking b, bool canManage) {
    final progress = _progress;
    final payments = progress?.payments ?? b.payments;

    return [
      if (progress != null) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress.statusLabel,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: c.champagne,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.paidPercent.round()}% · ${formatMoney(progress.paidTotal)} of ${formatMoney(progress.totalAmount)}',
                style: GoogleFonts.outfit(color: c.textSecondary),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progress.paidPercent / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: c.mutedSoft,
                  color: progress.balanceDue > 0 ? c.champagne : c.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (canManage && (progress?.canEditPackage ?? true)) ...[
        Text(
          'PACKAGE AMOUNT',
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _packageAmount,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: c.text),
                decoration: _fieldDecoration('Total Rs'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: PcButton(
                label: 'Save',
                loading: _savingPackage,
                colors: c,
                onPressed: _savingPackage ? null : _savePackage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
      if (canManage && (progress?.canEditPayments ?? true)) ...[
        Text(
          'RECORD PAYMENT',
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _payAmount,
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(color: c.text),
          decoration: _fieldDecoration('Amount'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final method in ['cash', 'bank', 'card', 'other'])
              ChoiceChip(
                label: Text(method[0].toUpperCase() + method.substring(1)),
                selected: _payMethod == method,
                onSelected: (_) => setState(() => _payMethod = method),
                selectedColor: c.champagne,
                backgroundColor: c.surface,
                labelStyle: GoogleFonts.outfit(
                  color: _payMethod == method ? c.textOnAccent : c.textSecondary,
                ),
                side: BorderSide(color: c.border),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final label in [
              '1st installment',
              '2nd installment',
              '3rd installment',
              'Balance',
            ])
              ChoiceChip(
                label: Text(label),
                selected: _payLabel == label,
                onSelected: (_) => setState(() => _payLabel = label),
                selectedColor: c.accentSoft,
                backgroundColor: c.surface,
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  color: c.text,
                ),
                side: BorderSide(color: c.border),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 12),
        PcButton(
          label: 'Add payment',
          loading: _savingPay,
          colors: c,
          onPressed: _savingPay ? null : _addPayment,
        ),
        const SizedBox(height: 24),
      ],
      Text(
        'INSTALLMENTS',
        style: GoogleFonts.outfit(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w500,
          color: c.textMuted,
        ),
      ),
      const SizedBox(height: 8),
      if (payments.isEmpty)
        Text(
          'No payments recorded yet.',
          style: GoogleFonts.outfit(color: c.textMuted),
        )
      else
        for (final p in payments)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.label,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                      Text(
                        '${p.method} · ${p.paidAt}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(p.amount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: c.champagne,
                  ),
                ),
              ],
            ),
          ),
    ];
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: GoogleFonts.outfit(color: c.textMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: GoogleFonts.outfit(
              color: c.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: c.textMuted),
      filled: true,
      fillColor: c.backgroundElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: c.champagne, width: 1.4),
      ),
    );
  }
}
