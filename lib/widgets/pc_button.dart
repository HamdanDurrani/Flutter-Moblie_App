import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum PcButtonVariant { primary, secondary, ghost, danger }

class PcButton extends StatelessWidget {
  const PcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = PcButtonVariant.primary,
    this.colors,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final PcButtonVariant variant;
  final ThemeColors? colors;

  @override
  Widget build(BuildContext context) {
    final c = colors ?? AppColors.dark;
    final disabled = onPressed == null || loading;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case PcButtonVariant.primary:
        bg = c.champagne;
        fg = c.textOnAccent;
      case PcButtonVariant.secondary:
        bg = Colors.transparent;
        fg = c.text;
        border = Border.all(color: c.borderStrong);
      case PcButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.text;
      case PcButtonVariant.danger:
        bg = c.dangerSoft;
        fg = c.danger;
        border = Border.all(color: c.danger.withValues(alpha: 0.45));
    }

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: border,
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
