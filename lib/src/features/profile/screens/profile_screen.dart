import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/jwt_utils.dart';
import '../../auth/providers/auth_provider.dart';

/// ProfileScreen — 기존 My Room 화면(사용자의 러닝 레벨, 대시보드, 누적 거리, 평균 페이스 등)과
/// 프로필 탭의 유저 관리 기능(실제 JWT 기반 닉네임 조회, 로그아웃 버튼)을 완벽하게 통합한 새로운 프로필 화면.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _bg = Color(0xFFFBF1EC);
  static const Color _primary = Color(0xFFDD6A3E);
  static const Color _primarySoft = Color(0xFFF7CDB8);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1F1A17);
  static const Color _textSub = Color(0xFF8C857F);

  String _nickname = 'Baton User';
  String _email = 'loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final pair = await ref.read(tokenStorageProvider).read();
      final token = pair?.accessToken;
      if (token != null && token.isNotEmpty) {
        final nick = nicknameFromAccessToken(token);
        final mail = emailFromAccessToken(token);
        if (mounted) {
          setState(() {
            _nickname = nick ?? 'Baton User';
            _email = mail ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildAppBar(context),
            const SizedBox(height: 12),
            _buildHeroAvatar(),
            const SizedBox(height: 20),
            Text(
              _nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isLoading ? '불러오는 중...' : (_email.isEmpty ? 'Pro Runner' : _email),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            _buildLevelCard(),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.straighten_rounded,
                    label: '총 거리',
                    value: '124.8 km',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.speed_rounded,
                    label: '평균 페이스',
                    value: "5'42\"",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BigActionCard(
                    icon: Icons.emoji_events_rounded,
                    title: '러닝 히스토리',
                    subtitle: '레벨 혜택 및 기록',
                    filled: true,
                    onTap: () => context.push(AppRoutes.history),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _BigActionCard(
                    icon: Icons.place_rounded,
                    title: '나의 스팟',
                    subtitle: '저장된 코스 확인',
                    filled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: _primary,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'Baton',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: _primary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(
            Icons.logout_rounded,
            color: _primary,
            size: 24,
          ),
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  Widget _buildHeroAvatar() {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.3),
            radius: 0.95,
            colors: [
              Color(0xFFF5A57E),
              Color(0xFFD96A3F),
              Color(0xFF8E3A1E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33D96A3F),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    const double progress = 0.6;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: _cardLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '러닝 레벨',
            style: TextStyle(
              fontSize: 14,
              color: _textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Lv.12',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  height: 1.0,
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '다음 레벨까지 240 EXP',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: _primarySoft.withValues(alpha: 0.45),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEBD9CC),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFDD6A3E), size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8C857F),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1A17),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFDD6A3E);
    const Color cardSoft = Color(0xFFFCE6DA);
    const Color textPrimary = Color(0xFF1F1A17);
    const Color textSub = Color(0xFF8C857F);

    final bg = filled ? primary : cardSoft;
    final fg = filled ? Colors.white : textPrimary;
    final subFg = filled ? Colors.white.withValues(alpha: 0.85) : textSub;
    final iconBg = filled
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.7);
    final iconColor = filled ? Colors.white : primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: Color(0x33D96A3F),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}