import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFC26740),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '바통',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDD6A3E),
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: user == null ? null : () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                tooltip: '로그아웃',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileHero(user: user),
          const SizedBox(height: 20),
          _ScoreCard(points: user?.totalPoints ?? 0),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniMetric(
                  title: '닉네임',
                  value: user?.nickname ?? '-',
                  icon: Icons.badge_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  title: '이메일',
                  value: user?.email ?? '-',
                  icon: Icons.mail_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.realname ?? '바통 user1';
    final String subtitle = user?.nickname ?? 'Pro Runner';

    return Column(
      children: <Widget>[
        Container(
          width: 146,
          height: 146,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFF79262), Color(0xFFCC4E1D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFE26639).withValues(alpha: 0.34),
                blurRadius: 30,
                spreadRadius: 6,
                offset: const Offset(0, 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 22,
            color: Color(0xFF7E7F84),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFE7E8EA),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: <Widget>[
          const Text(
            '러닝 지수',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8B8D94)),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$points',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE8683B),
                    letterSpacing: -1.4,
                  ),
                ),
                const TextSpan(
                  text: ' pts',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFCE5A31),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7E8EA),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: const Color(0xFFE8683B), size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF90939A), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}