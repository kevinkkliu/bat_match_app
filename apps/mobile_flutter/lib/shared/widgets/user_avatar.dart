import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFEAF1E7),
    this.foregroundColor = const Color(0xFF1E6B42),
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl = _normalizedAvatarUrl(avatarUrl);
    final Widget fallback = _FallbackAvatar(
      name: name,
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );

    if (normalizedUrl == null) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: Image.network(
          normalizedUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return fallback;
          },
        ),
      ),
    );
  }

  String? _normalizedAvatarUrl(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return null;
    }

    return trimmed;
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.name,
    required this.radius,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        _initial(name),
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _initial(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}
