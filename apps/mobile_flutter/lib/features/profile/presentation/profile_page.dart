import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/skill_level.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_callout.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../application/profile_providers.dart';
import '../data/profile_repository.dart';

enum _AuthMode { signIn, register }

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final GlobalKey<FormState> _authFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  final TextEditingController _identifierController = TextEditingController(
    text: 'kevin.seed@example.com',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'kevin.seed@example.com',
  );
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: 'password123',
  );
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _avatarController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _lineIdController = TextEditingController();

  _AuthMode _authMode = _AuthMode.signIn;
  String _skillLevel = 'L3';
  String _gender = 'UNDISCLOSED';
  bool _busy = false;
  String? _loadedUserId;

  @override
  void dispose() {
    _identifierController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _avatarController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _lineIdController.dispose();
    super.dispose();
  }

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
            error: (Object error, StackTrace _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  SectionCard(
                    title: '個人資料',
                    subtitle: '無法載入目前帳號。',
                    child: Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF8E493A),
                          ),
                    ),
                  ),
                ],
              );
            },
            data: (ProfileSession session) {
              _syncFormControllers(session.user);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  _ProfileHero(
                    user: session.user,
                    session: session,
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'MVP 核心欄位',
                    subtitle: '先把這四項填好，系統才更容易幫你媒合；其他欄位都可以之後再補。',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _CoreFieldChip(
                          icon: Icons.badge_outlined,
                          label: '暱稱',
                        ),
                        _CoreFieldChip(
                          icon: Icons.sports_tennis_rounded,
                          label: '程度',
                        ),
                        _CoreFieldChip(
                          icon: Icons.location_city_rounded,
                          label: '偏好城市',
                        ),
                        _CoreFieldChip(
                          icon: Icons.map_outlined,
                          label: '偏好行政區',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '帳號狀態',
                    subtitle: '訪客可先瀏覽場次；登入後才能保存資料、開團與管理申請。',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _StatusRow(
                          label: '登入狀態',
                          value: _sessionAccessLabel(session),
                        ),
                        const SizedBox(height: 12),
                        _StatusRow(
                          label: '目前使用者',
                          value:
                              session.isGuest ? '尚未登入' : session.user.nickname,
                        ),
                        const SizedBox(height: 12),
                        _SkillStatusRow(
                          label: '程度',
                          value: skillLevelLabel(session.user.skillLevel),
                          helperText:
                              skillLevelHelperText(session.user.skillLevel),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _sessionAccessHint(session),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF627266),
                                    height: 1.45,
                                  ),
                        ),
                        if (_busy) ...<Widget>[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: _authMode == _AuthMode.signIn ? '登入' : '註冊',
                    subtitle: _authMode == _AuthMode.signIn
                        ? '使用 Email、手機或 LINE 進入；登入後才會保存個人資料與報名狀態。'
                        : '建立帳號前，請先補齊暱稱、程度與偏好城市 / 行政區。',
                    child: Form(
                      key: _authFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ToggleButtons(
                            isSelected: <bool>[
                              _authMode == _AuthMode.signIn,
                              _authMode == _AuthMode.register,
                            ],
                            onPressed: (int index) {
                              setState(() {
                                _authMode = index == 0
                                    ? _AuthMode.signIn
                                    : _AuthMode.register;
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            constraints: const BoxConstraints(
                                minHeight: 44, minWidth: 110),
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('登入'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('註冊'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loginWithLine,
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text('使用 LINE 登入 / 註冊'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF06C755), // LINE Green
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('或'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_authMode == _AuthMode.signIn) ...<Widget>[
                            TextFormField(
                              controller: _identifierController,
                              decoration: const InputDecoration(
                                labelText: 'Email 或手機（必填）',
                                helperText: '登入時請輸入你註冊帳號時用的 Email 或手機。',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '請輸入 Email 或手機，才能登入。';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ] else ...<Widget>[
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email（至少填一項）',
                                helperText: '如果沒有手機，也可以只填 Email。',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateRegisterContact,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: '手機號碼（至少填一項）',
                                helperText: '如果沒有 Email，也可以只填手機號碼。',
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: '密碼（至少 8 碼）',
                              helperText: '請使用至少 8 個字元，登入後才能保存資料。',
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (String? value) {
                              if (value == null || value.trim().length < 8) {
                                return '密碼至少需要 8 個字元。';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton(
                                  onPressed: _busy ? null : _submitAuth,
                                  child: Text(
                                    _authMode == _AuthMode.signIn
                                        ? '登入'
                                        : '建立帳號',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: '個人資料設定',
                    subtitle: '上方四個欄位是 MVP 核心；這裡的資料會直接對應到 API，登入後才能真正保存。',
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              labelText: '暱稱（必填）',
                              helperText: '主揪與球友會看到這個名稱。',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return '請輸入暱稱，主揪與球友才找得到你。';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _avatarController,
                            decoration: const InputDecoration(
                              labelText: '大頭貼網址（選填）',
                              helperText: '沒有也沒關係，之後再補上即可。',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                    labelText: '性別（選填）',
                                  ),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                      value: 'UNDISCLOSED',
                                      child: Text('未公開'),
                                    ),
                                    DropdownMenuItem(
                                        value: 'MALE', child: Text('男')),
                                    DropdownMenuItem(
                                        value: 'FEMALE', child: Text('女')),
                                    DropdownMenuItem(
                                        value: 'OTHER', child: Text('其他')),
                                  ],
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() => _gender = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _skillLevel,
                                  decoration: InputDecoration(
                                    labelText: '程度（必填）',
                                    helperText:
                                        skillLevelHelperText(_skillLevel),
                                  ),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                      value: 'L1',
                                      child: Text('L1 新手'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'L2',
                                      child: Text('L2 初階'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'L3',
                                      child: Text('L3 中階'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'L4',
                                      child: Text('L4 進階'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'L5',
                                      child: Text('L5 競技'),
                                    ),
                                  ],
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() => _skillLevel = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: '偏好城市（必填）',
                                    helperText: '例：台北市、台中市、台南市。',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '請填偏好城市，方便媒合附近球局。';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _districtController,
                                  decoration: const InputDecoration(
                                    labelText: '偏好行政區（必填）',
                                    helperText: '例：大安區、北屯區、東區。',
                                  ),
                                  validator: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '請填偏好行政區，方便縮小搜尋範圍。';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lineIdController,
                            decoration: const InputDecoration(
                              labelText: 'LINE ID（選填）',
                              helperText: '只有你自己願意公開時再填；核准後才有機會用來聯絡。',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const StatusCallout(
                            title: '聯絡資料只在核准後公開',
                            message:
                                '電話與 LINE ID 會在主揪接受後才對對方可見；訪客、待審核、被拒絕或已撤回都看不到。',
                            icon: Icons.privacy_tip_rounded,
                            tone: StatusCalloutTone.info,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy || !session.hasServerIdentity
                                ? null
                                : () => _saveProfile(session),
                            child: Text(
                              session.hasServerIdentity ? '儲存資料' : '請先登入後儲存',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _busy || !session.isAuthenticated
                                ? null
                                : () => _logout(),
                            child: const Text('登出'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _syncFormControllers(ProfileUser user) {
    if (_loadedUserId == user.id) {
      return;
    }

    _loadedUserId = user.id;
    _nicknameController.text = user.nickname;
    _avatarController.text = user.avatarUrl ?? '';
    _gender = user.gender ?? 'UNDISCLOSED';
    _skillLevel = user.skillLevel;
    _cityController.text = user.preferredCity ?? '';
    _districtController.text = user.preferredDistrict ?? '';
    _lineIdController.text = user.lineId ?? '';
  }

  Future<void> _loginWithLine() async {
    final Uri currentPage = Uri.base;
    final Uri callbackTarget = currentPage.replace(
      path: '/auth/callback',
      queryParameters: <String, String>{},
      fragment: '',
    );
    final String loginBase = AppConfig.apiBaseUrl.isNotEmpty
        ? AppConfig.apiBaseUrl
        : currentPage.origin;
    final Uri url = Uri.parse(
      '$loginBase/api/v1/auth/line/login',
    ).replace(
      queryParameters: <String, String>{
        'redirectTo': callbackTarget.toString(),
      },
    );
    await launchUrl(url, webOnlyWindowName: '_self');
  }

  Future<void> _submitAuth() async {
    final FormState? form = _authFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_authMode == _AuthMode.register &&
        !(_profileFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _busy = true);

    try {
      final ProfileRepository repository = ref.read(profileRepositoryProvider);

      if (_authMode == _AuthMode.signIn) {
        await repository.login(
          ProfileLoginInput(
            emailOrPhone: _identifierController.text,
            password: _passwordController.text,
          ),
        );
      } else {
        final String? email = _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim();
        final String? phone = _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim();

        if (email == null && phone == null) {
          _showSnackBar('註冊時請輸入 Email 或手機。');
          return;
        }

        await repository.register(
          ProfileRegisterInput(
            email: email ?? '',
            phoneNumber: phone ?? '',
            password: _passwordController.text,
            nickname: _nicknameController.text,
            skillLevel: _skillLevel,
          ),
        );
      }

      ref.invalidate(profileSessionProvider);
      await ref.read(profileSessionProvider.future);
      _showSnackBar(
        _authMode == _AuthMode.signIn ? '登入成功。' : '帳號建立成功。',
      );
    } on DioException catch (error) {
      _showSnackBar(_extractErrorMessage(error));
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveProfile(ProfileSession session) async {
    final FormState? form = _profileFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _busy = true);

    try {
      final ProfileUser updated =
          await ref.read(profileRepositoryProvider).updateCurrentUser(
                ProfileUpdateInput(
                  nickname: _nicknameController.text,
                  avatarUrl: _avatarController.text,
                  gender: _gender,
                  skillLevel: _skillLevel,
                  preferredCity: _cityController.text,
                  preferredDistrict: _districtController.text,
                  lineId: _lineIdController.text,
                ),
                token: session.token,
              );

      _syncFormControllers(updated);
      ref.invalidate(profileSessionProvider);
      await ref.read(profileSessionProvider.future);
      _showSnackBar('資料已儲存。');
    } on DioException catch (error) {
      _showSnackBar(_extractErrorMessage(error));
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);

    try {
      await ref.read(profileRepositoryProvider).clearSession();
      _loadedUserId = null;
      ref.invalidate(profileSessionProvider);
      await ref.read(profileSessionProvider.future);
      _showSnackBar('已登出。');
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _extractErrorMessage(DioException error) {
    final dynamic data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final Object? message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return error.message ?? '發生未知錯誤。';
  }

  String? _validateRegisterContact(String? value) {
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      return 'Email 或手機至少填一項，才能建立帳號。';
    }

    return null;
  }
}

String _sessionAccessLabel(ProfileSession session) {
  if (session.isAuthenticated) {
    return '正式登入';
  }

  if (session.isPreview) {
    return '預覽登入';
  }

  return '訪客試用';
}

String _sessionAccessHint(ProfileSession session) {
  if (session.isAuthenticated) {
    return '你已經登入，可直接保存資料、開團、加入球局與管理申請。';
  }

  if (session.isPreview) {
    return '這是預覽登入，可直接操作示範帳號；重新整理後會回到預覽狀態。';
  }

  return '訪客可以先瀏覽與試填，按下儲存前請先登入或註冊，資料才會寫入帳號。';
}

String _sessionBadgeLabel(ProfileSession session) {
  if (session.isAuthenticated) {
    return '已登入';
  }

  if (session.isPreview) {
    return '預覽帳號';
  }

  return '訪客試用';
}

IconData _sessionBadgeIcon(ProfileSession session) {
  if (session.isAuthenticated) {
    return Icons.verified_rounded;
  }

  if (session.isPreview) {
    return Icons.visibility_rounded;
  }

  return Icons.person_outline_rounded;
}

String _preferredLocationLabel(ProfileUser user) {
  final String city = user.preferredCity?.trim() ?? '';
  final String district = user.preferredDistrict?.trim() ?? '';

  if (city.isEmpty && district.isEmpty) {
    return '尚未設定偏好城市 / 行政區';
  }

  if (city.isEmpty) {
    return district;
  }

  if (district.isEmpty) {
    return city;
  }

  return '$city · $district';
}

String _sessionSummary(ProfileSession session) {
  return '${skillLevelHelperText(session.user.skillLevel)}'
      '${session.isGuest ? '（訪客模式不會保存這些設定）' : ''}';
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.session,
  });

  final ProfileUser user;
  final ProfileSession session;

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
            Color(0xFF284C36),
            Color(0xFF101F18),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                UserAvatar(
                  name: user.nickname,
                  avatarUrl: user.avatarUrl,
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                const Spacer(),
                _HeroBadge(
                  label: _sessionBadgeLabel(session),
                  icon: _sessionBadgeIcon(session),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              user.nickname,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${skillLevelLabel(user.skillLevel)} • ${_preferredLocationLabel(user)}',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sessionSummary(session),
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CoreFieldChip extends StatelessWidget {
  const _CoreFieldChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E8DD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF1E6B42)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF1E6B42),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF627266),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF173321),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _SkillStatusRow extends StatelessWidget {
  const _SkillStatusRow({
    required this.label,
    required this.value,
    required this.helperText,
  });

  final String label;
  final String value;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: const Color(0xFF627266),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF173321),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helperText,
          textAlign: TextAlign.right,
          style: textTheme.bodySmall?.copyWith(
            color: const Color(0xFF627266),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
