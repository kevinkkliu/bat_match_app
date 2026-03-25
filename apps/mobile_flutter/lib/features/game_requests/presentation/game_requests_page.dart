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
import '../application/game_requests_providers.dart';

class GameRequestsPage extends ConsumerStatefulWidget {
  const GameRequestsPage({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  ConsumerState<GameRequestsPage> createState() => _GameRequestsPageState();
}

class _GameRequestsPageState extends ConsumerState<GameRequestsPage> {
  String? _busyJoinRequestId;
  String? _busyGameAction;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProfileSession> sessionAsync =
        ref.watch(profileSessionProvider);

    if (sessionAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (sessionAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Join Requests')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SectionCard(
            title: 'Join Requests',
            subtitle: 'Could not load your account state.',
            child: Text(sessionAsync.error.toString()),
          ),
        ),
      );
    }

    final ProfileSession session = sessionAsync.requireValue;
    if (!session.hasServerIdentity) {
      return Scaffold(
        appBar: AppBar(title: const Text('Join Requests')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AuthRequiredCard(
            title: 'Host moderation is locked for guests',
            message:
                'Sign in before reviewing or managing join requests for a game.',
            onSignInPressed: () => context.go(AppRoutePaths.profile),
          ),
        ),
      );
    }

    final AsyncValue<GameDetail> detailAsync =
        ref.watch(gameDetailProvider(widget.gameId));
    final AsyncValue<List<JoinRequestSummary>> requestsAsync =
        ref.watch(gameJoinRequestsProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: AsyncStateView(
        isLoading: detailAsync.isLoading || requestsAsync.isLoading,
        errorMessage: detailAsync.hasError
            ? detailAsync.error.toString()
            : requestsAsync.hasError
                ? requestsAsync.error.toString()
                : null,
        child: detailAsync.maybeWhen(
          data: (GameDetail detail) {
            return requestsAsync.maybeWhen(
              data: (List<JoinRequestSummary> requests) {
                final int pendingCount = requests
                    .where(
                      (JoinRequestSummary request) =>
                          request.status == 'PENDING',
                    )
                    .length;
                final int approvedCount = requests
                    .where(
                      (JoinRequestSummary request) =>
                          request.status == 'APPROVED',
                    )
                    .length;
                final int rejectedCount = requests
                    .where(
                      (JoinRequestSummary request) =>
                          request.status == 'REJECTED',
                    )
                    .length;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      _RequestsHero(
                        detail: detail,
                        pendingCount: pendingCount,
                        approvedCount: approvedCount,
                        rejectedCount: rejectedCount,
                        totalCount: requests.length,
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Host actions',
                        subtitle: 'Make quick updates or cancel the game.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'You can update the title, fee, capacity, and notes without leaving this page.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF55655B),
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _busyGameAction == null
                                        ? () => _handleEditGame(detail)
                                        : null,
                                    icon: const Icon(Icons.edit_rounded),
                                    label: const Text('Edit game'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _busyGameAction == null
                                        ? () => _handleCancelGame(detail)
                                        : null,
                                    icon: const Icon(Icons.cancel_rounded),
                                    label: const Text('Cancel game'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: detail.title,
                        subtitle: '${detail.city} · ${detail.district}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(detail.venueName),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatDate(detail.startAt)} ${_formatTime(detail.startAt)} - ${_formatTime(detail.endAt)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Available spots: ${detail.availableSpots}/${detail.capacity}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Moderation summary',
                        subtitle: 'Fast scan for host decisions',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _CountChip(
                              label: 'Pending',
                              value: pendingCount,
                              accent: Colors.orange,
                            ),
                            _CountChip(
                              label: 'Approved',
                              value: approvedCount,
                              accent: Colors.green,
                            ),
                            _CountChip(
                              label: 'Rejected',
                              value: rejectedCount,
                              accent: Colors.red,
                            ),
                            _CountChip(
                              label: 'Total',
                              value: requests.length,
                              accent: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Host requests',
                        subtitle: requests.isEmpty
                            ? 'No join requests yet.'
                            : 'Review and moderate pending requests.',
                        child: requests.isEmpty
                            ? const Text('New requests will appear here.')
                            : Column(
                                children:
                                    requests.map((JoinRequestSummary request) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _JoinRequestTile(
                                      request: request,
                                      isBusy: _busyJoinRequestId == request.id,
                                      onApprove: () => _handleApprove(request),
                                      onReject: () => _handleReject(request),
                                    ),
                                  );
                                }).toList(growable: false),
                              ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(gameDetailProvider(widget.gameId));
    ref.invalidate(gameJoinRequestsProvider(widget.gameId));
    await Future.wait(<Future<void>>[
      ref.read(gameDetailProvider(widget.gameId).future).then((_) {}),
      ref.read(gameJoinRequestsProvider(widget.gameId).future).then((_) {}),
    ]);
  }

  Future<void> _handleApprove(JoinRequestSummary request) async {
    await _runAction(
      request,
      () => ref.read(gamesRepositoryProvider).approveJoinRequest(request.id),
      successMessage: 'Request approved.',
    );
  }

  Future<void> _handleReject(JoinRequestSummary request) async {
    await _runAction(
      request,
      () => ref.read(gamesRepositoryProvider).rejectJoinRequest(request.id),
      successMessage: 'Request rejected.',
    );
  }

  Future<void> _handleEditGame(GameDetail detail) async {
    final _GameEditDraft? draft = await showDialog<_GameEditDraft>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController titleController =
            TextEditingController(text: detail.title);
        final TextEditingController feeController =
            TextEditingController(text: detail.fee.toString());
        final TextEditingController capacityController =
            TextEditingController(text: detail.capacity.toString());
        final TextEditingController notesController =
            TextEditingController(text: detail.notes ?? '');

        return AlertDialog(
          title: const Text('Edit game'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fee'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String title = titleController.text.trim();
                final int? fee = int.tryParse(feeController.text.trim());
                final int? capacity =
                    int.tryParse(capacityController.text.trim());

                if (title.isEmpty ||
                    fee == null ||
                    fee < 0 ||
                    capacity == null ||
                    capacity <= 0) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _GameEditDraft(
                    title: title,
                    fee: fee,
                    capacity: capacity,
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (draft == null) {
      return;
    }

    setState(() => _busyGameAction = 'edit');

    try {
      await ref.read(gamesRepositoryProvider).updateGame(
            widget.gameId,
            title: draft.title,
            fee: draft.fee,
            capacity: draft.capacity,
            notes: draft.notes,
          );

      await _refresh();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game updated.')),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ??
                error.message ??
                'Update failed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _busyGameAction = null);
      }
    }
  }

  Future<void> _handleCancelGame(GameDetail detail) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Cancel game?'),
              content: Text(
                'This will close the game and mark all active requests as cancelled.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Keep it open'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Cancel game'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _busyGameAction = 'cancel');

    try {
      await ref.read(gamesRepositoryProvider).updateGameStatus(
            widget.gameId,
            'CANCELLED',
          );

      await _refresh();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${detail.title} was cancelled.')),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ??
                error.message ??
                'Cancel failed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _busyGameAction = null);
      }
    }
  }

  Future<void> _runAction(
    JoinRequestSummary request,
    Future<JoinRequestSummary> Function() action, {
    required String successMessage,
  }) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busyJoinRequestId = request.id);

    try {
      await action();
      ref.invalidate(gameDetailProvider(widget.gameId));
      ref.invalidate(gameJoinRequestsProvider(widget.gameId));
      ref.invalidate(gamesListProvider);
      ref.invalidate(createdGamesProvider);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } on DioException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ??
                error.message ??
                'Action failed.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busyJoinRequestId = null);
      }
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
}

class _GameEditDraft {
  const _GameEditDraft({
    required this.title,
    required this.fee,
    required this.capacity,
    required this.notes,
  });

  final String title;
  final int fee;
  final int capacity;
  final String notes;
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color background = accent.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestTile extends StatelessWidget {
  const _JoinRequestTile({
    required this.request,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final JoinRequestSummary request;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bool isPending = request.status == 'PENDING';
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color statusColor = switch (request.status) {
      'PENDING' => Colors.orange,
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      'WITHDRAWN' => Colors.grey,
      'CANCELLED' => Colors.grey,
      _ => Colors.blueGrey,
    };
    final String displayName =
        request.applicant?.nickname ?? 'User ${_shortId(request.userId)}';
    final String? applicantNickname = request.applicant?.nickname;
    final String detailLine = request.applicant == null
        ? 'User ${_shortId(request.userId)}'
        : [
            request.applicant!.skillLevel,
            if (request.applicant!.preferredCity != null)
              request.applicant!.preferredCity!,
            if (request.applicant!.preferredDistrict != null)
              request.applicant!.preferredDistrict!,
          ].join(' · ');
    final String initial =
        applicantNickname != null && applicantNickname.isNotEmpty
            ? applicantNickname.substring(0, 1).toUpperCase()
            : (request.userId.isNotEmpty
                ? request.userId.substring(0, 1).toUpperCase()
                : '?');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 5, color: statusColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: statusColor,
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
                            'Request ${_shortId(request.id)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF173321),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF55655B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: request.status, accent: statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  detailLine,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6A7A70),
                  ),
                ),
                const SizedBox(height: 10),
                if (request.message != null &&
                    request.message!.isNotEmpty) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      request.message!,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF405147),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _InfoPill(
                      icon: Icons.schedule_rounded,
                      label: 'Requested ${_formatDateTime(request.createdAt)}',
                    ),
                    if (request.applicant?.gender != null)
                      _InfoPill(
                        icon: Icons.person_rounded,
                        label: request.applicant!.gender!,
                      ),
                    if (request.applicant?.skillLevel != null)
                      _InfoPill(
                        icon: Icons.sports_tennis_rounded,
                        label: request.applicant!.skillLevel,
                      ),
                    if (request.respondedAt != null)
                      _InfoPill(
                        icon: Icons.history_rounded,
                        label:
                            'Responded ${_formatDateTime(request.respondedAt!)}',
                      ),
                  ],
                ),
                if (isPending) ...<Widget>[
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: isBusy ? null : onApprove,
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isBusy ? null : onReject,
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortId(String value) {
    return value.length <= 8 ? value : value.substring(0, 8);
  }

  String _formatDateTime(DateTime dateTime) {
    final String date =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final String time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
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

class _RequestsHero extends StatelessWidget {
  const _RequestsHero({
    required this.detail,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.totalCount,
  });

  final GameDetail detail;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
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
                    Icons.shield_moon_rounded,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _HeroBadge(
                  label: '$totalCount requests',
                  icon: Icons.inbox_rounded,
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
              '${detail.city} · ${detail.district}',
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
                    label: 'Pending $pendingCount',
                    icon: Icons.hourglass_top_rounded),
                _HeroChip(
                    label: 'Approved $approvedCount',
                    icon: Icons.verified_rounded),
                _HeroChip(
                    label: 'Rejected $rejectedCount',
                    icon: Icons.block_rounded),
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
