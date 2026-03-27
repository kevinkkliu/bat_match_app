import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../shared/models/game_summary.dart';
import '../../../shared/widgets/auth_required_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../games/application/games_providers.dart';
import '../../games/data/games_repository.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile_repository.dart';

class CreateGamePage extends ConsumerStatefulWidget {
  const CreateGamePage({super.key});

  @override
  ConsumerState<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends ConsumerState<CreateGamePage> {
  final TextEditingController _titleController = TextEditingController(
    text: '週六中階雙打',
  );
  final TextEditingController _cityController = TextEditingController(
    text: '台北市',
  );
  final TextEditingController _districtController = TextEditingController(
    text: '大安區',
  );
  final TextEditingController _venueNameController = TextEditingController(
    text: '台大體育館',
  );
  final TextEditingController _venueAddressController = TextEditingController(
    text: '羅斯福路四段 1 號',
  );
  final TextEditingController _feeController =
      TextEditingController(text: '220');
  final TextEditingController _capacityController =
      TextEditingController(text: '8');
  final TextEditingController _courtCountController =
      TextEditingController(text: '2');
  final TextEditingController _notesController = TextEditingController(
    text: '由 Flutter 表單建立。',
  );

  DateTime _selectedDate = DateTime.utc(2026, 4, 2);
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  String _skillLevelMin = 'L2';
  String? _skillLevelMax = 'L4';
  String _approvalMode = 'AUTO';
  String? _shuttleType = 'FEATHER';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProfileSession> sessionAsync =
        ref.watch(profileSessionProvider);

    return Scaffold(
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
        child: SafeArea(
          child: sessionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                _CreateHero(isSubmitting: _submitting),
                const SizedBox(height: 16),
                SectionCard(
                  title: '建立球局',
                  subtitle: '無法載入你的帳號狀態。',
                  child: Text(error.toString()),
                ),
              ],
            ),
            data: (ProfileSession session) {
              if (!session.hasServerIdentity) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: <Widget>[
                    _CreateHero(isSubmitting: _submitting),
                    const SizedBox(height: 16),
                    AuthRequiredCard(
                      title: '訪客無法使用主揪工具',
                      message: '訪客可以先瀏覽公開球局；登入後才能發佈球局、保存草稿與管理報名。',
                      onSignInPressed: () => context.go(AppRoutePaths.profile),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  _CreateHero(isSubmitting: _submitting),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '基本資訊',
                    subtitle: '先填球局名稱與場地資訊。',
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '球局名稱'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                decoration:
                                    const InputDecoration(labelText: '城市'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _districtController,
                                decoration:
                                    const InputDecoration(labelText: '行政區'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _venueNameController,
                          decoration: const InputDecoration(labelText: '場館名稱'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _venueAddressController,
                          decoration: const InputDecoration(labelText: '場館地址'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '時間安排',
                    subtitle: '選擇日期與時間區間。',
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: _pickDate,
                                child: Text(_formatDate(_selectedDate)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => _pickTime(isStart: true),
                                child: Text(_startTime.format(context)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => _pickTime(isStart: false),
                                child: Text(_endTime.format(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _DateSummaryTile(
                                label: '開始',
                                value: _startTime.format(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateSummaryTile(
                                label: '結束',
                                value: _endTime.format(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '球局規則',
                    subtitle: '設定程度與報名方式。',
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _skillLevelMin,
                                decoration:
                                    const InputDecoration(labelText: '最低程度'),
                                items: _skillItems,
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() => _skillLevelMin = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _skillLevelMax,
                                decoration:
                                    const InputDecoration(labelText: '最高程度'),
                                items: _skillItems,
                                onChanged: (String? value) {
                                  setState(() => _skillLevelMax = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _feeController,
                                decoration:
                                    const InputDecoration(labelText: '費用'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _capacityController,
                                decoration:
                                    const InputDecoration(labelText: '容量'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _courtCountController,
                                decoration:
                                    const InputDecoration(labelText: '場地數'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _approvalMode,
                                decoration:
                                    const InputDecoration(labelText: '審核方式'),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                      value: 'AUTO', child: Text('自動審核')),
                                  DropdownMenuItem(
                                      value: 'MANUAL', child: Text('人工審核')),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setState(() => _approvalMode = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _shuttleType,
                                decoration:
                                    const InputDecoration(labelText: '球種'),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                      value: 'FEATHER', child: Text('羽毛球')),
                                  DropdownMenuItem(
                                      value: 'NYLON', child: Text('尼龍球')),
                                  DropdownMenuItem(
                                      value: 'MIXED', child: Text('混合球種')),
                                ],
                                onChanged: (String? value) {
                                  setState(() => _shuttleType = value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '備註',
                    subtitle: '給會加入的球友一些補充資訊。',
                    child: TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: '備註'),
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: Icon(
                      _submitting
                          ? Icons.hourglass_top_rounded
                          : Icons.add_circle_rounded,
                    ),
                    label: Text(_submitting ? '建立中…' : '建立球局'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _feeController.dispose();
    _capacityController.dispose();
    _courtCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );

    if (result != null) {
      setState(() =>
          _selectedDate = DateTime.utc(result.year, result.month, result.day));
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay initialTime = isStart ? _startTime : _endTime;
    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (result != null) {
      setState(() {
        if (isStart) {
          _startTime = result;
        } else {
          _endTime = result;
        }
      });
    }
  }

  Future<void> _submit() async {
    final int? fee = int.tryParse(_feeController.text.trim());
    final int? capacity = int.tryParse(_capacityController.text.trim());
    final int? courtCount = int.tryParse(_courtCountController.text.trim());

    if (fee == null || capacity == null || courtCount == null) {
      _showMessage('費用、容量與場地數必須是有效數字。');
      return;
    }

    final DateTime startAt = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final DateTime endAt = DateTime.utc(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endAt.isAfter(startAt)) {
      _showMessage('結束時間必須晚於開始時間。');
      return;
    }

    setState(() => _submitting = true);

    try {
      final GameDetail created =
          await ref.read(gamesRepositoryProvider).createGame(
                CreateGameInput(
                  title: _titleController.text.trim(),
                  city: _cityController.text.trim(),
                  district: _districtController.text.trim(),
                  venueName: _venueNameController.text.trim(),
                  venueAddress: _venueAddressController.text.trim(),
                  gameDate: _formatDate(_selectedDate),
                  startAt: startAt.toIso8601String(),
                  endAt: endAt.toIso8601String(),
                  skillLevelMin: _skillLevelMin,
                  skillLevelMax: _skillLevelMax,
                  fee: fee,
                  capacity: capacity,
                  courtCount: courtCount,
                  shuttleType: _shuttleType,
                  approvalMode: _approvalMode,
                  notes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                ),
              );

      ref.invalidate(gamesListProvider);
      ref.invalidate(gameDetailProvider(created.id));

      if (!mounted) {
        return;
      }

      _showMessage('球局已建立。');
      context.goNamed(
        AppRouteNames.gameDetail,
        pathParameters: <String, String>{'gameId': created.id},
      );
    } on DioException catch (error) {
      _showMessage(
          error.response?.data?.toString() ?? error.message ?? '建立失敗。');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  List<DropdownMenuItem<String>> get _skillItems {
    return const <String>['L1', 'L2', 'L3', 'L4', 'L5']
        .map(
          (String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(_skillLevelDisplayLabel(value)),
          ),
        )
        .toList(growable: false);
  }
}

String _skillLevelDisplayLabel(String skillLevel) {
  switch (skillLevel.toUpperCase()) {
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

class _CreateHero extends StatelessWidget {
  const _CreateHero({
    required this.isSubmitting,
  });

  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1E6B42),
            Color(0xFF173321),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1E6B42).withValues(alpha: 0.18),
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
                    Icons.note_add_rounded,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _HeroBadge(
                  label: isSubmitting ? '儲存中…' : '預覽就緒',
                  icon: isSubmitting
                      ? Icons.hourglass_top_rounded
                      : Icons.phone_iphone_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '開一場清楚的球局',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '把表單分成清楚區塊，讓主揪快速掃過每個重點。',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                height: 1.45,
              ),
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

class _DateSummaryTile extends StatelessWidget {
  const _DateSummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF64706A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF173321),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
