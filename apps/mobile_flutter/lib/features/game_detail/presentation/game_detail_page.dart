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
      appBar: AppBar(title: const Text('球局詳情')),
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
              final ProfileSession session =
                  sessionAsync.valueOrNull ?? ProfileSession.guest();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  _GameDetailHero(detail: detail),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '狀態總覽',
                    subtitle: '先確認這場現在能不能操作。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        StatusCallout(
                          title: _detailStateTitle(detail, session),
                          message: _detailStateMessage(detail, session),
                          icon: _actionabilityIcon(detail),
                          tone: _detailStateTone(detail, session),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _DetailChip(
                              icon: _statusIcon(detail.status),
                              label: _gameStatusLabel(detail.status),
                            ),
                            _DetailChip(
                              icon: _actionabilityIcon(detail),
                              label: _actionabilityLabel(detail),
                            ),
                            _DetailChip(
                              icon: Icons.person_rounded,
                              label: detail.joinSummary.currentUserStatus ==
                                      null
                                  ? '你尚未建立申請'
                                  : '你目前是 ${_joinStatusLabel(detail.joinSummary.currentUserStatus!)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '快速資訊',
                    subtitle: '一眼看懂的重點資訊。',
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
                              '${detail.availableSpots}/${detail.capacity} 個名額',
                        ),
                        _DetailChip(
                          icon: Icons.sports_tennis_rounded,
                          label: _skillLevelRangeLabel(
                            detail.skillLevelMin,
                            detail.skillLevelMax,
                          ),
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
                    title: '場地',
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.45,
                                    color: const Color(0xFF55655B),
                                  ),
                        ),
                        const SizedBox(height: 14),
                        _DetailRow(
                          icon: Icons.sports_score_rounded,
                          label: '場地配置',
                          value:
                              '${detail.courtCount} 面場地 · ${_shuttleLabel(detail.shuttleType)}',
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.timelapse_rounded,
                          label: '時間區間',
                          value:
                              '${_formatDate(detail.startAt)} ${_formatTime(detail.startAt)} - ${_formatTime(detail.endAt)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '主揪',
                    subtitle: '這場球局的主揪與聯絡規則。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            UserAvatar(
                              name: detail.host.nickname,
                              avatarUrl: detail.host.avatarUrl,
                              radius: 20,
                              backgroundColor: const Color(0xFFEAF1E7),
                              foregroundColor: const Color(0xFF1E6B42),
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
                                    '${_skillLevelDisplayLabel(detail.host.skillLevel)}${detail.host.preferredCity == null ? '' : ' · ${detail.host.preferredCity}'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF55655B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _skillLevelHelperText(
                                        detail.host.skillLevel),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF627266),
                                          height: 1.35,
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
                              label: detail.host.preferredDistrict ?? '地區彈性',
                            ),
                            _DetailChip(
                              icon: Icons.badge_rounded,
                              label: detail.host.gender ?? '個人資料稍後顯示',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StatusCallout(
                          title: _contactVisibilityTitle(detail, session),
                          message: _contactVisibilityText(detail, session),
                          icon: _contactVisibilityIcon(detail, session),
                          tone: _contactVisibilityTone(detail, session),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _DetailChip(
                              icon: Icons.lock_open_rounded,
                              label: _contactVisibilityAudienceLabel(
                                detail,
                                session,
                              ),
                            ),
                            _DetailChip(
                              icon: Icons.visibility_off_rounded,
                              label: '未公開：訪客 / 待審核 / 已拒絕 / 已撤回',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (session.user.id == detail.host.id) ...<Widget>[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => context.pushNamed(
                                AppRouteNames.gameRequests,
                                pathParameters: <String, String>{
                                  'gameId': detail.id,
                                },
                              ),
                              icon: const Icon(Icons.rule_folder_rounded),
                              label: const Text('前往主揪工作台'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          '可聯絡資訊',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF1E6B42),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        if (_canViewContact(detail, session))
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F3),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDDE5D8),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (detail.host.phoneNumber != null)
                                  _DetailRow(
                                    icon: Icons.phone_rounded,
                                    label: '電話',
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
                                if (detail.host.phoneNumber == null &&
                                    detail.host.lineId == null)
                                  Text(
                                    '主揪尚未提供可公開的聯絡方式。',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF55655B),
                                          height: 1.45,
                                        ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Text(
                            '核准後才會顯示主揪聯絡方式；被拒絕、撤回或取消後都不會解鎖。',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF55655B),
                                  height: 1.45,
                                ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '報名摘要',
                    subtitle: '快速查看你目前的參與狀態。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _DetailChip(
                              icon: Icons.hourglass_top_rounded,
                              label: '待審核 ${detail.joinSummary.pendingCount}',
                            ),
                            _DetailChip(
                              icon: Icons.verified_rounded,
                              label: '已接受 ${detail.joinSummary.approvedCount}',
                            ),
                            _DetailChip(
                              icon: detail.isOpen
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              label: detail.isOpen ? '開放報名' : '已關閉報名',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          detail.joinSummary.currentUserStatus == null
                              ? '你在這場球局沒有進行中的申請。'
                              : '你目前的狀態：${_joinStatusLabel(detail.joinSummary.currentUserStatus!)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF55655B),
                                    height: 1.45,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: detail.approvalMode == 'MANUAL' ? '申請加入' : '直接加入',
                    subtitle: '先看這場球局的可操作狀態，再決定要不要加入或撤回。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        StatusCallout(
                          title: _joinSectionTitle(detail, session),
                          message: _joinSectionMessage(detail, session),
                          icon: _joinSectionIcon(detail, session),
                          tone: _joinSectionTone(detail, session),
                        ),
                        const SizedBox(height: 14),
                        session.isGuest
                            ? AuthRequiredCard(
                                title: '訪客無法使用報名功能',
                                message: '請先登入或註冊後，再申請名額、加入球局或管理既有申請。',
                                onSignInPressed: () =>
                                    context.go(AppRoutePaths.profile),
                                buttonLabel: '登入後加入',
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
                                            : () => _handleWithdraw(
                                                context, detail),
                                        icon: const Icon(Icons.logout_rounded),
                                        label: Text(
                                          detail.joinSummary
                                                      .currentUserStatus ==
                                                  'PENDING'
                                              ? '撤回申請'
                                              : '退出球局',
                                        ),
                                      ),
                                    ),
                                  ] else if (_canJoin(detail)) ...<Widget>[
                                    TextField(
                                      controller: _messageController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: '給主揪的訊息',
                                        hintText: '可選，寫給主揪看的補充說明',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _joining
                                            ? null
                                            : () => _handleJoin(context),
                                        icon: Icon(
                                          detail.approvalMode == 'MANUAL'
                                              ? Icons.send_rounded
                                              : Icons.check_circle_rounded,
                                        ),
                                        label: Text(
                                          detail.approvalMode == 'MANUAL'
                                              ? '申請加入'
                                              : '直接加入',
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
                      ],
                    ),
                  ),
                  if (detail.notes != null &&
                      detail.notes!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    SectionCard(
                      title: '備註',
                      subtitle: '主揪提供的補充資訊。',
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
            error.response?.data?.toString() ?? error.message ?? '加入失敗。',
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
            error.response?.data?.toString() ?? error.message ?? '撤回失敗。',
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

  String _joinDisabledText(GameDetail detail) {
    if (detail.status == 'CANCELLED') {
      return '這場球局已取消，已不能再加入。';
    }

    if (detail.status == 'COMPLETED') {
      return '這場球局已結束，已不能再加入。';
    }

    if (detail.joinSummary.currentUserStatus != null) {
      return '你的申請目前是 ${_joinStatusLabel(detail.joinSummary.currentUserStatus!)}。';
    }

    if (detail.status == 'FULL') {
      return '這場球局已額滿。';
    }

    if (!detail.isOpen) {
      return '這場球局目前暫時無法報名。';
    }

    if (detail.isFull) {
      return '這場球局已額滿。';
    }

    return '目前暫時無法報名。';
  }

  String _leaveHelpText(GameDetail detail) {
    if (detail.status == 'CANCELLED' || detail.status == 'COMPLETED') {
      return '這場球局已進入歷史狀態，申請不可再變更。';
    }

    if (detail.joinSummary.currentUserStatus == 'PENDING') {
      return '你的申請正在審核中，任何時候都可以撤回。';
    }

    if (detail.joinSummary.currentUserStatus == 'APPROVED') {
      return '你目前已被核准加入這場球局。如果臨時不能到，請直接退出。';
    }

    return '這筆申請已無法再變更。';
  }

  String _joinSuccessMessage(GameJoinResult result) {
    if (result.joinRequest.status == 'APPROVED') {
      return '已成功加入。';
    }

    if (result.joinRequest.status == 'PENDING') {
      return '加入申請已送出。';
    }

    return '已更新申請。';
  }

  String _withdrawSuccessMessage(GameDetail detail) {
    if (detail.joinSummary.currentUserStatus == 'APPROVED') {
      return '你已退出這場球局。';
    }

    return '申請已撤回。';
  }
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

String _skillLevelHelperText(String skillLevel) {
  switch (skillLevel.trim().toUpperCase()) {
    case 'L1':
      return '剛開始打球，重視熟悉球感與基本步伐。';
    case 'L2':
      return '已能穩定對打，節奏偏輕鬆或基礎磨合。';
    case 'L3':
      return '具備穩定對抗能力，適合一般社群球局。';
    case 'L4':
      return '接近進階球友，能維持較高回合強度。';
    case 'L5':
      return '競賽或高強度練球等級，球速與節奏都更快。';
    default:
      return '程度資訊稍後會顯示。';
  }
}

String _skillLevelRangeLabel(String minLevel, String? maxLevel) {
  if (maxLevel == null || maxLevel.trim().isEmpty) {
    return _skillLevelDisplayLabel(minLevel);
  }

  return '${_skillLevelDisplayLabel(minLevel)} - ${_skillLevelDisplayLabel(maxLevel)}';
}

String _shuttleLabel(String? shuttleType) {
  switch (shuttleType) {
    case 'FEATHER':
      return '羽毛球';
    case 'NYLON':
      return '尼龍球';
    case 'MIXED':
      return '混合球種';
    case null:
      return '球種待定';
  }

  return '球種待定';
}

String _joinStatusLabel(String status) {
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

String _gameStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'OPEN':
      return '開放中';
    case 'FULL':
      return '已額滿';
    case 'CANCELLED':
      return '已取消';
    case 'COMPLETED':
      return '已結束';
    default:
      return status;
  }
}

IconData _statusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'OPEN':
      return Icons.lock_open_rounded;
    case 'FULL':
      return Icons.warning_rounded;
    case 'CANCELLED':
      return Icons.cancel_rounded;
    case 'COMPLETED':
      return Icons.history_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

IconData _actionabilityIcon(GameDetail detail) {
  if (detail.isHistorical) {
    return Icons.history_rounded;
  }

  if (detail.isClosedForJoin) {
    return Icons.lock_rounded;
  }

  return Icons.touch_app_rounded;
}

String _actionabilityLabel(GameDetail detail) {
  if (detail.isHistorical) {
    return '歷史';
  }

  if (detail.isClosedForJoin) {
    return '已關閉';
  }

  return '可操作';
}

String _actionabilityText(GameDetail detail) {
  if (detail.status == 'CANCELLED') {
    return '這場球局已取消，不能再報名或撤回，但仍可查看歷史資訊。';
  }

  if (detail.status == 'COMPLETED') {
    return '這場球局已結束，不能再報名或撤回，但仍可保留查看。';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '你已被核准加入這場球局，現在可以查看聯絡方式，也可以在開打前退出。';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '你的申請還在審核中，這段期間只能查看進度，不能再重複送出。';
  }

  if (detail.status == 'FULL') {
    return '這場球局已額滿，除非有人退出，否則暫時不能再加入。';
  }

  if (detail.isOpen) {
    return '這場球局仍在開放中，登入後可以直接加入或送出申請。';
  }

  return '這場球局目前不是可加入狀態。';
}

String _detailStateTitle(GameDetail detail, ProfileSession session) {
  if (detail.isHistorical) {
    return '這場球局已進入歷史';
  }

  if (detail.isClosedForJoin) {
    return '這場球局目前已關閉報名';
  }

  if (session.isGuest) {
    return '訪客可以先看狀態';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '你已被核准加入';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '你的申請正在審核';
  }

  return '目前仍可操作';
}

String _detailStateMessage(GameDetail detail, ProfileSession session) {
  if (session.isGuest) {
    return '你可以先看球局資訊，登入後才能報名、撤回或查看自己的參與狀態。';
  }

  return _actionabilityText(detail);
}

StatusCalloutTone _detailStateTone(
  GameDetail detail,
  ProfileSession session,
) {
  if (detail.isHistorical) {
    return StatusCalloutTone.neutral;
  }

  if (detail.isClosedForJoin) {
    return StatusCalloutTone.warning;
  }

  if (session.isGuest) {
    return StatusCalloutTone.info;
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return StatusCalloutTone.success;
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return StatusCalloutTone.warning;
  }

  return StatusCalloutTone.info;
}

String _joinSectionTitle(GameDetail detail, ProfileSession session) {
  if (session.isGuest) {
    return '登入後才能報名';
  }

  if (detail.isHistorical) {
    return '這場球局已進入歷史';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '你已被核准加入';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '你的申請正在審核';
  }

  if (detail.isClosedForJoin) {
    return '這場球局已關閉報名';
  }

  return '現在可以操作';
}

String _joinSectionMessage(GameDetail detail, ProfileSession session) {
  if (session.isGuest) {
    return '登入後才能送出申請、撤回申請或查看自己的參與狀態。';
  }

  if (detail.status == 'CANCELLED') {
    return '這場球局已取消，無法再報名。';
  }

  if (detail.status == 'COMPLETED') {
    return '這場球局已結束，無法再報名。';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '你已被核准加入；開打前可以查看聯絡方式，也可以在需要時退出。';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '你的申請正在審核中，這段期間只能查看進度，不能再重複送出。';
  }

  if (detail.status == 'FULL') {
    return '這場球局已額滿，除非有人退出，否則暫時不能再加入。';
  }

  if (!detail.isOpen) {
    return '這場球局目前未開放報名。';
  }

  if (detail.isFull) {
    return '這場球局已額滿。';
  }

  return '登入後可以直接加入，或送出一段簡短訊息給主揪。';
}

StatusCalloutTone _joinSectionTone(
  GameDetail detail,
  ProfileSession session,
) {
  if (session.isGuest) {
    return StatusCalloutTone.info;
  }

  if (detail.isHistorical) {
    return StatusCalloutTone.neutral;
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return StatusCalloutTone.success;
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return StatusCalloutTone.warning;
  }

  if (detail.isClosedForJoin) {
    return StatusCalloutTone.warning;
  }

  return StatusCalloutTone.info;
}

IconData _joinSectionIcon(GameDetail detail, ProfileSession session) {
  if (session.isGuest) {
    return Icons.person_outline_rounded;
  }

  if (detail.isHistorical) {
    return Icons.history_rounded;
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return Icons.lock_open_rounded;
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return Icons.hourglass_top_rounded;
  }

  if (detail.isClosedForJoin) {
    return Icons.lock_rounded;
  }

  return Icons.touch_app_rounded;
}

String _contactVisibilityText(GameDetail detail, ProfileSession session) {
  if (session.user.id == detail.host.id) {
    return '你是主揪本人，電話與 LINE ID 已完整開放，也可以直接管理這場球局。';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '你已被核准加入這場球局，現在可以查看主揪的電話與 LINE ID。';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '你的申請還在待審核，電話與 LINE ID 目前還不會顯示。';
  }

  if (detail.joinSummary.currentUserStatus == 'REJECTED' ||
      detail.joinSummary.currentUserStatus == 'WITHDRAWN' ||
      detail.joinSummary.currentUserStatus == 'CANCELLED' ||
      detail.status == 'CANCELLED' ||
      detail.status == 'COMPLETED') {
    return '這筆申請不會再顯示主揪聯絡方式。';
  }

  return '核准後才會顯示聯絡方式；被拒絕、撤回或取消後都不會解鎖。';
}

String _contactVisibilityAudienceLabel(
  GameDetail detail,
  ProfileSession session,
) {
  if (session.user.id == detail.host.id) {
    return '公開對象：主揪本人（完整）';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '公開對象：主揪本人 / 已核准球友';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '公開對象：尚未開放';
  }

  if (detail.joinSummary.currentUserStatus == 'REJECTED' ||
      detail.joinSummary.currentUserStatus == 'WITHDRAWN' ||
      detail.joinSummary.currentUserStatus == 'CANCELLED' ||
      detail.status == 'CANCELLED' ||
      detail.status == 'COMPLETED') {
    return '公開對象：不再開放';
  }

  return '公開對象：核准後才開放';
}

String _contactVisibilityTitle(GameDetail detail, ProfileSession session) {
  if (session.user.id == detail.host.id) {
    return '你是主揪，聯絡方式已完整開放';
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return '已核准，主揪聯絡方式已解鎖';
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return '聯絡方式尚未解鎖';
  }

  if (detail.joinSummary.currentUserStatus == 'REJECTED' ||
      detail.joinSummary.currentUserStatus == 'WITHDRAWN') {
    return '這筆申請不會再顯示聯絡方式';
  }

  if (detail.status == 'CANCELLED') {
    return '球局已取消，聯絡方式不再開放';
  }

  if (detail.status == 'COMPLETED') {
    return '球局已結束，聯絡方式已轉為歷史資訊';
  }

  return '核准後才能查看主揪聯絡方式';
}

IconData _contactVisibilityIcon(GameDetail detail, ProfileSession session) {
  if (session.user.id == detail.host.id) {
    return Icons.manage_accounts_rounded;
  }

  if (detail.joinSummary.currentUserStatus == 'APPROVED') {
    return Icons.lock_open_rounded;
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return Icons.hourglass_top_rounded;
  }

  if (detail.joinSummary.currentUserStatus == 'REJECTED' ||
      detail.joinSummary.currentUserStatus == 'WITHDRAWN') {
    return Icons.do_not_disturb_on_rounded;
  }

  if (detail.status == 'CANCELLED' || detail.status == 'COMPLETED') {
    return Icons.history_rounded;
  }

  return Icons.lock_rounded;
}

StatusCalloutTone _contactVisibilityTone(
  GameDetail detail,
  ProfileSession session,
) {
  if (session.user.id == detail.host.id ||
      detail.joinSummary.currentUserStatus == 'APPROVED') {
    return StatusCalloutTone.success;
  }

  if (detail.joinSummary.currentUserStatus == 'PENDING') {
    return StatusCalloutTone.warning;
  }

  if (detail.joinSummary.currentUserStatus == 'REJECTED' ||
      detail.joinSummary.currentUserStatus == 'WITHDRAWN' ||
      detail.status == 'CANCELLED' ||
      detail.status == 'COMPLETED') {
    return StatusCalloutTone.neutral;
  }

  return StatusCalloutTone.info;
}

bool _canViewContact(GameDetail detail, ProfileSession session) {
  return session.user.id == detail.host.id ||
      detail.joinSummary.currentUserStatus == 'APPROVED';
}

class _GameDetailHero extends StatelessWidget {
  const _GameDetailHero({
    required this.detail,
  });

  final GameDetail detail;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = _gameStatusLabel(detail.status);
    final String approvalLabel =
        detail.approvalMode == 'MANUAL' ? '人工審核' : '自動審核';
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
                  icon: detail.status == 'FULL' || detail.status == 'CANCELLED'
                      ? Icons.warning_rounded
                      : detail.status == 'COMPLETED'
                          ? Icons.history_rounded
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
                  label: '${detail.availableSpots}/${detail.capacity} 個名額',
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
