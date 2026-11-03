import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.kind,
    required this.label,
    required this.colors,
  });

  final String kind;
  final String label;
  final ThemeColors colors;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;

    switch (kind) {
      case 'starting':
      case 'upcoming':
        bg = colors.isDark
            ? const Color(0x383E8F62)
            : const Color(0x243E8F62);
        fg = const Color(0xFF3E8F62);
      case 'tomorrow':
        bg = colors.isDark
            ? const Color(0x38B54A4A)
            : const Color(0x1FB54A4A);
        fg = const Color(0xFFB54A4A);
      case 'pending':
        bg = colors.isDark
            ? const Color(0x38C4A35A)
            : const Color(0x29C4A35A);
        fg = colors.champagne;
      case 'in_progress':
        bg = colors.mutedSoft;
        fg = colors.textSecondary;
      default:
        bg = colors.mutedSoft;
        fg = colors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.item,
    required this.colors,
    required this.onTap,
    this.showPayments = true,
    this.pendingMode = false,
  });

  final Booking item;
  final ThemeColors colors;
  final VoidCallback onTap;
  final bool showPayments;
  final bool pendingMode;

  @override
  Widget build(BuildContext context) {
    final chipKind = pendingMode ? 'pending' : item.liveKind;
    final chipLabel = pendingMode
        ? (item.totalAmount == 0
            ? 'Set the package'
            : '${formatMoney(item.balanceDue)} pending')
        : item.liveLabel;

    final ImageProvider thumb = item.stageImageUrl != null &&
            item.stageImageUrl!.isNotEmpty
        ? NetworkImage(item.stageImageUrl!)
        : AssetImage(eventThumbAsset(item.eventType));

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.border),
            boxShadow: colors.isDark
                ? null
                : [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      kind: chipKind,
                      label: chipLabel,
                      colors: colors,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        item.eventType,
                        if (item.stageRequired) 'Stage',
                        if (item.shiftLabel.isNotEmpty) item.shiftLabel,
                        '${formatHour(item.startHour)}–${formatHour(item.endHour)}',
                      ].join(' · '),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.guestName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.guestCount != null
                          ? 'Guest capacity · ${item.guestCount}'
                          : (item.guestRangeLabel != null
                              ? 'Guests · ${item.guestRangeLabel}'
                              : item.reservationNumber),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (showPayments) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.paidPercent.round()}% paid',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            item.balanceDue > 0
                                ? '${formatMoney(item.balanceDue)} due'
                                : 'Fully paid',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: item.balanceDue > 0
                                  ? colors.danger
                                  : colors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.paidPercent / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: colors.mutedSoft,
                          color: item.balanceDue > 0
                              ? colors.champagne
                              : colors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMoney(item.paidTotal)} of ${formatMoney(item.totalAmount)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.accentSoft,
                          child: Text(
                            () {
                              final name =
                                  item.acceptedByName ?? item.guestName;
                              return name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?';
                            }(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.champagne,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: item.acceptedByName ?? 'Office',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: colors.text,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${item.reservationNumber}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Image(
                      image: thumb,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: colors.mutedSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.shiftLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
