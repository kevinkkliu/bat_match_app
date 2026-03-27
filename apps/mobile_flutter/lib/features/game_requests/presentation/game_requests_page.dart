import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/auth_required_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_callout.dart';
import '../../../shared/widgets/user_avatar.dart';
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
        appBar: AppBar(title: const Text('報名申請')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SectionCard(
            title: '報名申請',
            subtitle: '無法載入你的帳號狀態。',
            child: Text(sessionAsync.error.toString()),
          ),
        ),
      );
    }

    final ProfileSession session = sessionAsync.requireValue;
    if (!session.hasServerIdentity) {
      return Scaffold(
        appBar: AppBar(title: const Text('報名申請')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AuthRequiredCard(
            title: '訪客無法使用主揪審核',
            message: '請先登入，再查看或管理這場球局的報名申請。',
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
      appBar: AppBar(title: const Text('報名申請')),
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
                final List<JoinRequestSummary> pendingRequests =
                    requests.where((JoinRequestSummary request) {
                  return request.isPending;
                }).toList(growable: false);
                final List<JoinRequestSummary> approvedRequests =
                    requests.where((JoinRequestSummary request) {
                  return request.isApproved;
                }).toList(growable: false);
                final List<JoinRequestSummary> historyRequests =
                    requests.where((JoinRequestSummary request) {
                  return request.isRejected || request.isWithdrawn;
                }).toList(growable: false);
                final int pendingCount = pendingRequests.length;
                final int approvedCount = approvedRequests.length;
                final int historyCount = historyRequests.length;

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
                        historyCount: historyCount,
                        totalCount: requests.length,
                      ),
                      const SizedBox(height: 16),
                      StatusCallout(
                        title: '主揪工作台',
                        message:
                            '先處理待審核申請，再看參加名單，最後回看處理紀錄。已接受的球友才會進入名單，也才會被視為可聯絡對象。',
                        icon: Icons.manage_accounts_rounded,
                        tone: StatusCalloutTone.info,
                      ),
                      const SizedBox(height: 12),
                      StatusCallout(
                        title: '名單摘要',
                        message:
                            '已接受 ${approvedRequests.length} 位球友，待審核 ${pendingRequests.length} 位球友。',
                        icon: Icons.groups_rounded,
                        tone: StatusCalloutTone.success,
                        trailing: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            const _NameChip(
                              label: '參加名單',
                              accent: Color(0xFF1E6B42),
                            ),
                            const _NameChip(
                              label: '報名申請',
                              accent: Color(0xFFDA8A18),
                            ),
                            ...approvedRequests.map(
                              (JoinRequestSummary request) => _NameChip(
                                label: request.applicant?.nickname ??
                                    '使用者 ${_shortId(request.userId)}',
                                accent: const Color(0xFF1E6B42),
                              ),
                            ),
                            ...pendingRequests.map(
                              (JoinRequestSummary request) => _NameChip(
                                label: request.applicant?.nickname ??
                                    '使用者 ${_shortId(request.userId)}',
                                accent: Colors.orange,
                              ),
                            ),
                            _CountChip(
                              label: '已接受',
                              value: approvedRequests.length,
                              accent: const Color(0xFF1E6B42),
                            ),
                            _CountChip(
                              label: '待審核',
                              value: pendingRequests.length,
                              accent: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RequestGroupCard(
                        key: const ValueKey<String>('pending-requests-card'),
                        title: '報名申請',
                        subtitle: pendingRequests.isEmpty
                            ? '目前沒有待處理的申請。'
                            : '先處理這一區，再看已接受名單與歷史紀錄。',
                        emptyTitle: '目前沒有待審核申請',
                        emptyMessage: '新申請進來時，會先出現在這裡。',
                        emptyIcon: Icons.inbox_rounded,
                        emptyTone: StatusCalloutTone.neutral,
                        requests: pendingRequests,
                        showActions: true,
                        busyRequestId: _busyJoinRequestId,
                        onApprove: _handleApprove,
                        onReject: _handleReject,
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '參加名單',
                        subtitle: approvedRequests.isEmpty
                            ? '目前還沒有已接受的球友。'
                            : '已接受、且名額已保留的球友會留在這裡。',
                        child: approvedRequests.isEmpty
                            ? const StatusCallout(
                                title: '參加名單尚未建立',
                                message: '接受一筆申請後，這裡就會開始累積已接受的球友。',
                                icon: Icons.groups_rounded,
                                tone: StatusCalloutTone.neutral,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: approvedRequests.isNotEmpty
                                    ? <Widget>[
                                        StatusCallout(
                                          title: '已接受名單摘要',
                                          message: _requestNamesSummary(
                                              approvedRequests),
                                          icon: Icons.verified_rounded,
                                          tone: StatusCalloutTone.success,
                                        ),
                                        const SizedBox(height: 12),
                                        ...approvedRequests.map(
                                          (JoinRequestSummary request) =>
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: _ParticipantTile(
                                              request: request,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : <Widget>[],
                              ),
                      ),
                      if (historyRequests.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _RequestGroupCard(
                          title: '處理紀錄',
                          subtitle: '已拒絕、已撤回與已取消的申請，會保留在這裡供回看。',
                          emptyTitle: '處理紀錄已清空',
                          emptyMessage: '等到有人撤回或被拒絕，這裡才會累積紀錄。',
                          emptyIcon: Icons.history_rounded,
                          emptyTone: StatusCalloutTone.neutral,
                          requests: historyRequests,
                          showActions: false,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _HostActionCard(
                        detail: detail,
                        isBusy: _busyGameAction != null,
                        onEdit: () => _handleEditGame(detail),
                        onCancel: () => _handleCancelGame(detail),
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
                              '剩餘名額：${detail.availableSpots}/${detail.capacity}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '目前名單：$approvedCount/${detail.capacity}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: '審核摘要',
                        subtitle: '快速查看待審核、已接受與處理紀錄的分布。',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _CountChip(
                              label: '待審核',
                              value: pendingCount,
                              accent: Colors.orange,
                            ),
                            _CountChip(
                              label: '已接受',
                              value: approvedCount,
                              accent: Colors.green,
                            ),
                            _CountChip(
                              label: '已處理',
                              value: historyCount,
                              accent: Colors.red,
                            ),
                            _CountChip(
                              label: '總數',
                              value: requests.length,
                              accent: Theme.of(context).colorScheme.primary,
                            ),
                          ],
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
      successMessage: '申請已接受。',
    );
  }

  Future<void> _handleReject(JoinRequestSummary request) async {
    await _runAction(
      request,
      () => ref.read(gamesRepositoryProvider).rejectJoinRequest(request.id),
      successMessage: '申請已拒絕。',
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
          title: const Text('編輯球局'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '球局名稱'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '費用'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '容量'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: '備註'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
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
              child: const Text('儲存'),
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
        const SnackBar(content: Text('球局已更新。')),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ?? error.message ?? '更新失敗。',
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
              title: const Text('取消球局？'),
              content: Text(
                '這會關閉球局，並把所有進行中的申請標記為已取消。',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('先不取消'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('取消球局'),
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
        SnackBar(content: Text('${detail.title} 已取消。')),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?.toString() ?? error.message ?? '取消失敗。',
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
            error.response?.data?.toString() ?? error.message ?? '操作失敗。',
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
    super.key,
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
        request.applicant?.nickname ?? '使用者 ${_shortId(request.userId)}';
    final String detailLine = request.applicant == null
        ? '使用者 ${_shortId(request.userId)}'
        : [
            _skillLevelDisplayLabel(request.applicant!.skillLevel),
            if (request.applicant!.preferredCity != null)
              request.applicant!.preferredCity!,
            if (request.applicant!.preferredDistrict != null)
              request.applicant!.preferredDistrict!,
          ].join(' · ');
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
                    UserAvatar(
                      name: displayName,
                      avatarUrl: request.applicant?.avatarUrl,
                      radius: 20,
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      foregroundColor: statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '申請 ${_shortId(request.id)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF173321),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '申請人',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF55655B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: _requestStatusLabel(request.status),
                      accent: statusColor,
                    ),
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
                      label: '申請於 ${_formatDateTime(request.createdAt)}',
                    ),
                    if (request.applicant?.gender != null)
                      _InfoPill(
                        icon: Icons.person_rounded,
                        label: request.applicant!.gender!,
                      ),
                    if (request.applicant?.skillLevel != null)
                      _InfoPill(
                        icon: Icons.sports_tennis_rounded,
                        label: _skillLevelDisplayLabel(
                            request.applicant!.skillLevel),
                      ),
                    if (request.respondedAt != null)
                      _InfoPill(
                        icon: Icons.history_rounded,
                        label: '回覆於 ${_formatDateTime(request.respondedAt!)}',
                      ),
                  ],
                ),
                if (isPending) ...<Widget>[
                  const SizedBox(height: 14),
                  const StatusCallout(
                    title: '待審核申請',
                    message: '這位球友目前還沒進入名單；接受後才會算入參加人數，也才會進入聯絡 handoff 範圍。',
                    icon: Icons.hourglass_top_rounded,
                    tone: StatusCalloutTone.warning,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: isBusy ? null : onApprove,
                          child: const Text('接受'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isBusy ? null : onReject,
                          child: const Text('拒絕'),
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
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.request,
  });

  final JoinRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final JoinRequestApplicant? applicant = request.applicant;
    final String displayName =
        applicant?.nickname ?? '使用者 ${_shortId(request.userId)}';
    final String detailLine = applicant == null
        ? '使用者 ${_shortId(request.userId)}'
        : [
            _skillLevelDisplayLabel(applicant.skillLevel),
            if (applicant.preferredCity != null) applicant.preferredCity!,
            if (applicant.preferredDistrict != null)
              applicant.preferredDistrict!,
          ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFF1E6B42).withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UserAvatar(
                  name: displayName,
                  avatarUrl: applicant?.avatarUrl,
                  radius: 20,
                  backgroundColor:
                      const Color(0xFF1E6B42).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF1E6B42),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF173321),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已接受球友',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF55655B),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: '已接受',
                  accent: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatusBadge(
                  label: '可聯絡',
                  accent: Colors.teal,
                ),
                _StatusBadge(
                  label: '已進名單',
                  accent: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detailLine,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6A7A70),
              ),
            ),
            if (request.approvedAt != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoPill(
                icon: Icons.verified_rounded,
                label: '已接受於 ${_formatDateTime(request.approvedAt!)}',
              ),
              const SizedBox(height: 10),
              const StatusCallout(
                title: '聯絡方式已解鎖',
                message: '這位球友已被接受，後續聯絡、出席確認與名單追蹤都可以直接進行。',
                icon: Icons.lock_open_rounded,
                tone: StatusCalloutTone.success,
              ),
            ],
          ],
        ),
      ),
    );
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
    required this.historyCount,
    required this.totalCount,
  });

  final GameDetail detail;
  final int pendingCount;
  final int approvedCount;
  final int historyCount;
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
                  label: '共 $totalCount 筆申請',
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
                    label: '待審核 $pendingCount',
                    icon: Icons.hourglass_top_rounded),
                _HeroChip(
                    label: '已接受 $approvedCount', icon: Icons.verified_rounded),
                _HeroChip(
                    label: '名單 $approvedCount/${detail.capacity}',
                    icon: Icons.groups_rounded),
                _HeroChip(
                    label: '已處理 $historyCount', icon: Icons.history_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HostActionCard extends StatelessWidget {
  const _HostActionCard({
    required this.detail,
    required this.isBusy,
    required this.onEdit,
    required this.onCancel,
  });

  final GameDetail detail;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '主揪管理',
      subtitle: '先改球局資料，再決定要不要取消。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StatusCallout(
            title: '主揪工作台',
            message: '不用離開這個頁面，就能更新球局名稱、費用、容量與備註，或直接取消這場球局。',
            icon: detail.isHistorical
                ? Icons.history_rounded
                : detail.isClosedForJoin
                    ? Icons.lock_rounded
                    : Icons.manage_accounts_rounded,
            tone: detail.isHistorical
                ? StatusCalloutTone.neutral
                : detail.isClosedForJoin
                    ? StatusCalloutTone.warning
                    : StatusCalloutTone.info,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('編輯球局'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onCancel,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('取消球局'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestGroupCard extends StatelessWidget {
  const _RequestGroupCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.emptyTone,
    required this.requests,
    required this.showActions,
    this.busyRequestId,
    this.onApprove,
    this.onReject,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final StatusCalloutTone emptyTone;
  final List<JoinRequestSummary> requests;
  final bool showActions;
  final String? busyRequestId;
  final Future<void> Function(JoinRequestSummary request)? onApprove;
  final Future<void> Function(JoinRequestSummary request)? onReject;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: subtitle,
      child: requests.isEmpty
          ? StatusCallout(
              title: emptyTitle,
              message: emptyMessage,
              icon: emptyIcon,
              tone: emptyTone,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StatusCallout(
                  title: '$title摘要',
                  message: _requestNamesSummary(requests),
                  icon: emptyIcon,
                  tone: emptyTone,
                ),
                const SizedBox(height: 12),
                ...requests.map(
                  (JoinRequestSummary request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JoinRequestTile(
                      key: ValueKey<String>('join-request-${request.id}'),
                      request: request,
                      isBusy: busyRequestId == request.id,
                      onApprove: showActions && onApprove != null
                          ? () {
                              onApprove!(request);
                            }
                          : () {},
                      onReject: showActions && onReject != null
                          ? () {
                              onReject!(request);
                            }
                          : () {},
                    ),
                  ),
                ),
              ],
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

String _requestNamesSummary(List<JoinRequestSummary> requests) {
  if (requests.isEmpty) {
    return '目前沒有可顯示的名單。';
  }

  return '共 ${requests.length} 位球友';
}

class _NameChip extends StatelessWidget {
  const _NameChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
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

String _skillLevelDisplayLabel(String skillLevel) {
  switch (skillLevel.trim().toUpperCase()) {
    case 'L1':
      return 'L1 初學入門';
    case 'L2':
      return 'L2 穩定練習中';
    case 'L3':
      return 'L3 穩定球友';
    case 'L4':
      return 'L4 高階球友';
    case 'L5':
      return 'L5 競賽程度';
    default:
      return skillLevel;
  }
}

String _requestStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return '待審核';
    case 'APPROVED':
      return '已接受';
    case 'REJECTED':
      return '已拒絕';
    case 'WITHDRAWN':
      return '已撤回';
    case 'CANCELLED':
      return '已取消';
    default:
      return status;
  }
}
