import 'package:flutter/material.dart';

enum StatusCalloutTone {
  neutral,
  info,
  success,
  warning,
  danger,
}

class StatusCallout extends StatelessWidget {
  const StatusCallout({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.tone = StatusCalloutTone.neutral,
    this.trailing,
  });

  final String title;
  final String message;
  final IconData icon;
  final StatusCalloutTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final _StatusPalette palette = _paletteForTone(context, tone);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: palette.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.titleColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.messageColor,
                    height: 1.45,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(height: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
}

_StatusPalette _paletteForTone(BuildContext context, StatusCalloutTone tone) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;

  return switch (tone) {
    StatusCalloutTone.info => _StatusPalette(
        background: const Color(0xFFEAF1E7),
        border: const Color(0xFFCDE0CA),
        iconBackground: const Color(0xFFDDE8D9),
        iconColor: const Color(0xFF1E6B42),
        titleColor: const Color(0xFF173321),
        messageColor: const Color(0xFF55655B),
      ),
    StatusCalloutTone.success => _StatusPalette(
        background: const Color(0xFFEAF5EE),
        border: const Color(0xFFBFE0C8),
        iconBackground: const Color(0xFFD9F0E0),
        iconColor: const Color(0xFF178246),
        titleColor: const Color(0xFF173321),
        messageColor: const Color(0xFF55655B),
      ),
    StatusCalloutTone.warning => _StatusPalette(
        background: const Color(0xFFFFF6E8),
        border: const Color(0xFFF0D7A7),
        iconBackground: const Color(0xFFF8E3BD),
        iconColor: const Color(0xFFAA6B0F),
        titleColor: const Color(0xFF4A3210),
        messageColor: const Color(0xFF6F5A39),
      ),
    StatusCalloutTone.danger => _StatusPalette(
        background: const Color(0xFFFDEEEE),
        border: const Color(0xFFF0C0C0),
        iconBackground: const Color(0xFFF8DADA),
        iconColor: const Color(0xFFB23B3B),
        titleColor: const Color(0xFF4A1C1C),
        messageColor: const Color(0xFF6D4848),
      ),
    StatusCalloutTone.neutral => _StatusPalette(
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
        iconBackground: colorScheme.surface,
        iconColor: colorScheme.primary,
        titleColor: colorScheme.onSurface,
        messageColor: colorScheme.onSurfaceVariant,
      ),
  };
}
