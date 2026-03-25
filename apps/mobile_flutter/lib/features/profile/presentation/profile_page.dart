import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/section_card.dart';
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
                    title: 'Profile',
                    subtitle: 'Could not load the current account.',
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
                    isAuthenticated: session.isAuthenticated,
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Account status',
                    subtitle:
                        'Guest mode can browse games. Sign in unlocks create, join, and My Games.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _StatusRow(
                          label: 'Session',
                          value: session.isAuthenticated
                              ? 'JWT saved securely'
                              : session.isPreview
                                  ? 'Preview mode via dev header'
                                  : 'Guest browsing only',
                        ),
                        const SizedBox(height: 12),
                        _StatusRow(
                          label: 'Current user',
                          value: session.user.nickname,
                        ),
                        const SizedBox(height: 12),
                        _StatusRow(
                          label: 'Skill',
                          value: session.user.skillLevel,
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
                    title: _authMode == _AuthMode.signIn
                        ? 'Sign in'
                        : 'Create account',
                    subtitle: _authMode == _AuthMode.signIn
                        ? 'Use email or phone to unlock a persistent session.'
                        : 'Use the profile fields below for nickname and skill level.',
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
                                child: Text('Sign in'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Register'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loginWithLine,
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text('Continue with LINE'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF06C755), // LINE Green
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
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_authMode == _AuthMode.signIn) ...<Widget>[
                            TextFormField(
                              controller: _identifierController,
                              decoration: const InputDecoration(
                                labelText: 'Email or phone',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email or phone is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ] else ...<Widget>[
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _passwordController,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (String? value) {
                              if (value == null || value.trim().length < 8) {
                                return 'Password must be at least 8 characters.';
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
                                        ? 'Sign in'
                                        : 'Create account',
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
                    title: 'Profile settings',
                    subtitle:
                        'These fields map directly to the API profile record.',
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _nicknameController,
                            decoration:
                                const InputDecoration(labelText: 'Nickname'),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nickname is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _avatarController,
                            decoration:
                                const InputDecoration(labelText: 'Avatar URL'),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                      labelText: 'Gender'),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                      value: 'UNDISCLOSED',
                                      child: Text('UNDISCLOSED'),
                                    ),
                                    DropdownMenuItem(
                                        value: 'MALE', child: Text('MALE')),
                                    DropdownMenuItem(
                                        value: 'FEMALE', child: Text('FEMALE')),
                                    DropdownMenuItem(
                                        value: 'OTHER', child: Text('OTHER')),
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
                                  decoration: const InputDecoration(
                                      labelText: 'Skill level'),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem(
                                        value: 'L1', child: Text('L1')),
                                    DropdownMenuItem(
                                        value: 'L2', child: Text('L2')),
                                    DropdownMenuItem(
                                        value: 'L3', child: Text('L3')),
                                    DropdownMenuItem(
                                        value: 'L4', child: Text('L4')),
                                    DropdownMenuItem(
                                        value: 'L5', child: Text('L5')),
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
                                      labelText: 'Preferred city'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _districtController,
                                  decoration: const InputDecoration(
                                      labelText: 'Preferred district'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lineIdController,
                            decoration: const InputDecoration(
                                labelText: 'LINE ID (Optional)'),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy || !session.hasServerIdentity
                                ? null
                                : () => _saveProfile(session),
                            child: const Text('Save profile'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _busy || !session.isAuthenticated
                                ? null
                                : () => _logout(),
                            child: const Text('Logout'),
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
    final Uri url = Uri.base.replace(path: '/api/v1/auth/line/login');
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
          _showSnackBar('Email or phone is required for registration.');
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
        _authMode == _AuthMode.signIn
            ? 'Signed in successfully.'
            : 'Account created successfully.',
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
      _showSnackBar('Profile saved.');
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
      _showSnackBar('Logged out.');
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

    return error.message ?? 'Something went wrong.';
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.isAuthenticated,
  });

  final ProfileUser user;
  final bool isAuthenticated;

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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: Text(
                    user.nickname.isNotEmpty
                        ? user.nickname.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                _HeroBadge(
                  label: isAuthenticated
                      ? 'Signed in'
                      : user.id == 'guest'
                          ? 'Guest'
                          : 'Preview',
                  icon: isAuthenticated
                      ? Icons.verified_rounded
                      : user.id == 'guest'
                          ? Icons.person_outline_rounded
                          : Icons.visibility_rounded,
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
              'Skill ${user.skillLevel} • ${user.preferredCity ?? 'No preferred city yet'}',
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
