import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/character_sphere_widget.dart';
import '../../core/character/character_style.dart';
import '../group_running/services/group_run_api_service.dart';
import '../profile/screens/member_profile_screen.dart';
import '../../core/follow/models/follow_request_model.dart';
import '../../core/follow/providers/follow_providers.dart';
import '../../core/utils/app_snack_bar.dart';

class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  static const Color _primary = Color(0xFFDD6A3E);
  static const Color _bg = Color(0xFFF4F4F4);
  static const Color _textSub = Color(0xFF8C857F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingFollowRequestsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _primary,
        ),
        title: const Text(
          '팔로우 신청',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1A17),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () async => ref.invalidate(pendingFollowRequestsProvider),
        child: requestsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primary),
          ),
          error: (e, _) => _buildError(ref),
          data: (requests) => requests.isEmpty
              ? _buildEmpty()
              : _buildList(context, ref, requests),
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '신청 목록을 불러오지 못했어요.',
                  style: TextStyle(color: _textSub, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(pendingFollowRequestsProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none_rounded, size: 48, color: Color(0xFFCCCCCC)),
                SizedBox(height: 12),
                Text(
                  '받은 팔로우 신청이 없어요.',
                  style: TextStyle(color: Color(0xFF8C857F), fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<FollowRequestModel> requests,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _FollowRequestTile(request: request);
      },
    );
  }
}

class _FollowRequestTile extends ConsumerStatefulWidget {
  const _FollowRequestTile({required this.request});
  final FollowRequestModel request;

  @override
  ConsumerState<_FollowRequestTile> createState() => _FollowRequestTileState();
}

class _FollowRequestTileState extends ConsumerState<_FollowRequestTile> {
  bool _isLoading = false;
  String _colorCode = 'CORE_ORANGE';

  static const Color _primary = Color(0xFFDD6A3E);

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  Future<void> _loadColor() async {
    try {
      final colorMap = await ref
          .read(groupRunApiServiceProvider)
          .fetchProfileColorsBatch([widget.request.memberId]);
      final code = colorMap[widget.request.memberId];
      if (code != null && mounted) setState(() => _colorCode = code);
    } catch (_) {}
  }

  Future<void> _handle(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      ref.invalidate(pendingFollowRequestsProvider);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '처리 중 오류가 발생했어요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(followServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemberProfileScreen(nickname: widget.request.nickname),
                ),
              ),
              child: Row(
                children: [
                  CharacterSphereWidget(
                    style: CharacterStylePresets.fromCode(_colorCode),
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.request.nickname,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1A17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
            )
          else ...[
            _ActionButton(
              label: '수락',
              filled: true,
              onTap: () => _handle(
                () => service.accept(widget.request.followId),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: '거절',
              filled: false,
              onTap: () => _handle(
                () => service.reject(widget.request.followId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFFDD6A3E);

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(58, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF666666),
        side: const BorderSide(color: Color(0xFFCCCCCC)),
        minimumSize: const Size(58, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
