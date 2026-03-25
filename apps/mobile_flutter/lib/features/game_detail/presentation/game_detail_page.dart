import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/auth_required_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../games/application/games_providers.dart';
import '../../games/data/games_repository.dart';
import '../../my_games/application/my_games_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile_repository.dart';

class GameDetailPage extends ConsumerStatefulWidget {
  const GameDetailPage({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  bool _joining = false;
  bool _withdrawing = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProfileSession> sessionAsync =
        ref.watch(profileSessionProvider);
    final AsyncValue<GameDetail> detailAsync =
        ref.watch(gameDetailProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Game Detail')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF6F1E8),
              Color(0xFFF4F7EF),
            ],
          ),
        ),
        child: AsyncStateView(
          isLoading: detailAsync.isLoading || sessionAsync.isLoading,
          errorMessage: detailAsync.hasError
              ? detailAsync.error.toString()
              : sessionAsync.hasError
                  ? sessionAsync.error.toString()
                  : null,
          child: detailAsync.maybeWhen(
            data: (GameDetail detail) {
              final ProfileSession session = sessionAsync.valueOrNull ??
                  ProfileSession.guest();

              return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                _GameDetailHero(detail: detail),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Quick facts',
                  subtitle: 'The essentials at a glance.',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _DetailChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${_formatDate(detail.startAt)} ${_formatTime(detail.startAt)}',
                      ),
                      _DetailChip(
                        icon: Icons.group_rounded,
                        label:
                            '${detail.availableSpots}/${detail.capacity} spots left',
                      ),
                      _DetailChip(
                        icon: Icons.sports_tennis_rounded,
                        label:
                            '${detail.skillLevelMin}${detail.skillLevelMax == null ? '' : ' - ${detail.skillLevelMax}'}',
                      ),
                      _DetailChip(
                        icon: Icons.attach_money_rounded,
                        label: 'NT\$${detail.fee}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Venue',
                  subtitle: '${detail.city} · ${detail.district}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        detail.venueName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF173321),
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail.venueAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              color: const Color(0xFF55655B),
                            ),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.sports_score_rounded,
                        label: 'Court setup',
                        value:
                            '${detail.courtCount} courts · ${detail.shuttleType ?? 'Mixed shuttle'}',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.timelapse_rounded,
                        label: 'Window',
                        value:
                            '${_formatDate(detail.startAt)} ${_formatTime(detail.startAt)} - ${_formatTime(detail.endAt)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Host',
                  subtitle: 'The person running this game.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEAF1E7),
                            child: Text(
                              detail.host.nickname.isNotEmpty
                                  ? detail.host.nickname
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF1E6B42),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  detail.host.nickname,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF173321),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${detail.host.skillLevel}${detail.host.preferredCity == null ? '' : ' · ${detail.host.preferredCity}'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF55655B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _DetailChip(
                            icon: Icons.location_city_rounded,
                            label: detail.host.preferredDistrict ??
                                'Region flexible',
                          ),
                          _DetailChip(
                            icon: Icons.badge_rounded,
                            label:
                                detail.host.gender ?? 'Profile visible later',
                          ),
                        ],
                      ),
                      if (detail.host.phoneNumber != null ||
                          detail.host.lineId != null) ...<Widget>[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFEAF1E7)),
                        const SizedBox(height: 12),
                        Text(
                          'Contact Info (Visible since you are approved)',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF1E6B42),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (detail.host.phoneNumber != null)
                          _DetailRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone number',
                            value: detail.host.phoneNumber!,
                          ),
                        if (detail.host.phoneNumber != null &&
                            detail.host.lineId != null)
                          const SizedBox(height: 10),
                        if (detail.host.lineId != null)
                          _DetailRow(
                            icon: Icons.chat_bubble_rounded,
                            label: 'LINE ID',
                            value: detail.host.lineId!,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Join summary',
                  subtitle: 'Fast scan for your current membership state.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _DetailChip(
                            icon: Icons.hourglass_top_rounded,
                            label: 'Pending ${detail.joinSummary.pendingCount}',
                          ),
                          _DetailChip(
                            icon: Icons.verified_rounded,
                            label:
                                'Approved ${detail.joinSummary.approvedCount}',
                          ),
                          _DetailChip(
                            icon: detail.isOpen
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            label: detail.isOpen
                                ? 'Open for joining'
                                : 'Closed for joining',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detail.joinSummary.currentUserStatus == null
                            ? 'You have no active request on this game.'
                            : 'Your current status: ${detail.joinSummary.currentUserStatus}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF55655B),
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: detail.approvalMode == 'MANUAL'
                      ? 'Request to join'
                      : 'Join this game',
                  subtitle: _joinHelpText(detail),
                  child: session.isGuest
                      ? AuthRequiredCard(
                          title: 'Join actions are locked for guests',
                          message:
                              'Sign in or register before you request a spot, join a game, or manage an existing request.',
                          onSignInPressed: () =>
                              context.go(AppRoutePaths.profile),
                          buttonLabel: 'Sign in to join',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (_canWithdraw(detail)) ...<Widget>[
                              Text(
                                _leaveHelpText(detail),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF55655B),
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _withdrawing
                                      ? null
                                      : () => _handleWithdraw(context, detail),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: Text(
                                    detail.joinSummary.currentUserStatus ==
                                            'PENDING'
                                        ? 'Withdraw request'
                                        : 'Leave game',
                                  ),
                                ),
                              ),
                            ] else if (_canJoin(detail)) ...<Widget>[
                              TextField(
                                controller: _messageController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Message to host',
                                  hintText: 'Optional note for the host',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      _joining ? null : () => _handleJoin(context),
                                  icon: Icon(
                                    detail.approvalMode == 'MANUAL'
                                        ? Icons.send_rounded
                                        : Icons.check_circle_rounded,
                                  ),
                                  label: Text(
                                    detail.approvalMode == 'MANUAL'
                                        ? 'Request to join'
                                        : 'Join game',
                                  ),
                                ),
                              ),
                            ] else ...<Widget>[
                              Text(
                                _joinDisabledText(detail),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF55655B),
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ],
                        ),
                ),
                if (detail.notes != null &&
                    detail.notes!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Notes',
                    subtitle: 'Helpful context from the host.',
                    child: Text(
                      detail.notes!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF55655B),
                            height: 1.5,
                          ),
                    ),
                  ),
                ],
              ],
            );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _joining = true);

    try {
      final GameJoinResult result =
          await ref.read(gamesRepositoryProvider).joinGame(
                widget.gameId,
                message: _messageController.text.trim(),
              );

      ref.invalidate(gameDetailProvider(widget.gameId));
      ref.invalidate(gamesListProvider);
      ref.invalidate(joinedGamesProvider);
      ref.invalidate(createdGamesProvider);

      if (!mounted) {
        return;
      }

      _messageController.clear();
      messenger
          .showSnackBar(SnackBar(content: Text(_joinSuccessMessage(result))));
    } on DioException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ?? error.message ?? 'Join failed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _joining = false);
      }
    }
  }

  Future<void> _handleWithdraw(
    BuildContext context,
    GameDetail detail,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _withdrawing = true);

    try {
      await ref
          .read(gamesRepositoryProvider)
          .withdrawJoinRequestForGame(widget.gameId);

      ref.invalidate(gameDetailProvider(widget.gameId));
      ref.invalidate(gamesListProvider);
      ref.invalidate(joinedGamesProvider);

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(_withdrawSuccessMessage(detail))),
      );
    } on DioException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ??
                error.message ??
                'Withdraw failed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _withdrawing = false);
      }
    }
  }

  bool _canJoin(GameDetail detail) {
    return detail.isOpen &&
        !detail.isFull &&
        detail.joinSummary.currentUserStatus == null;
  }

  bool _canWithdraw(GameDetail detail) {
    return detail.joinSummary.currentUserStatus == 'PENDING' ||
        detail.joinSummary.currentUserStatus == 'APPROVED';
  }

  String _joinHelpText(GameDetail detail) {
    if (detail.joinSummary.currentUserStatus != null) {
      return 'You already have an active request on this game.';
    }

    if (!detail.isOpen) {
      return 'This game is not open for joining.';
    }

    if (detail.isFull) {
      return 'This game is currently full.';
    }

    return 'Add a short note if you want to introduce yourself to the host.';
  }

  String _joinDisabledText(GameDetail detail) {
    if (detail.joinSummary.currentUserStatus != null) {
      return 'Your request is already ${detail.joinSummary.currentUserStatus}.';
    }

    if (!detail.isOpen) {
      return 'This game is not open for joining right now.';
    }

    if (detail.isFull) {
      return 'This game is full.';
    }

    return 'Join is temporarily unavailable.';
  }

  String _leaveHelpText(GameDetail detail) {
    if (detail.joinSummary.currentUserStatus == 'PENDING') {
      return 'Your request is pending review. You can withdraw it at any time.';
    }

    if (detail.joinSummary.currentUserStatus == 'APPROVED') {
      return 'You are currently approved for this game. Leave now if you cannot make it.';
    }

    return 'You can no longer change this request.';
  }

  String _joinSuccessMessage(GameJoinResult result) {
    if (result.joinRequest.status == 'APPROVED') {
      return 'Joined successfully.';
    }

    if (result.joinRequest.status == 'PENDING') {
      return 'Join request sent.';
    }

    return 'Join updated.';
  }

  String _withdrawSuccessMessage(GameDetail detail) {
    if (detail.joinSummary.currentUserStatus == 'APPROVED') {
      return 'You left the game.';
    }

    return 'Request withdrawn.';
  }
}

class _GameDetailHero extends StatelessWidget {
  const _GameDetailHero({
    required this.detail,
  });

  final GameDetail detail;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = detail.isOpen ? 'Open' : 'Closed';
    final String approvalLabel =
        detail.approvalMode == 'MANUAL' ? 'Manual approval' : 'Auto approval';
    final String nextLine =
        '${detail.city} · ${detail.district} · ${_formatDate(detail.startAt)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF284C36),
            Color(0xFF101F18),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF284C36).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _HeroBadge(
                  label: statusLabel,
                  icon: detail.isFull
                      ? Icons.warning_rounded
                      : Icons.verified_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              detail.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              nextLine,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HeroChip(
                  label:
                      '${detail.availableSpots}/${detail.capacity} spots left',
                  icon: Icons.group_rounded,
                ),
                _HeroChip(
                  label: 'NT\$${detail.fee}',
                  icon: Icons.payments_rounded,
                ),
                _HeroChip(
                  label: approvalLabel,
                  icon: Icons.rule_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF5A6A60)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF55655B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1E7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1E6B42)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF627266),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF173321),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
