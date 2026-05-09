import 'package:flutter/material.dart';

import 'widgets/custom_input_field.dart';
import 'widgets/status_toggle.dart';

class CreateRoomBottomSheet extends StatefulWidget {
  const CreateRoomBottomSheet({
    super.key,
    this.onClose,
    this.onSubmit,
    this.titleController,
    this.membersController,
    this.startTimeController,
    this.locationController,
  });

  final VoidCallback? onClose;
  final VoidCallback? onSubmit;
  final TextEditingController? titleController;
  final TextEditingController? membersController;
  final TextEditingController? startTimeController;
  final TextEditingController? locationController;

  @override
  State<CreateRoomBottomSheet> createState() => _CreateRoomBottomSheetState();
}

class _CreateRoomBottomSheetState extends State<CreateRoomBottomSheet> {
  final List<String> _statuses = const ['모집중', '달리는 중', '완료', '취소됨'];
  String _selectedStatus = '모집중';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onClose: widget.onClose),
              const SizedBox(height: 18),
              const _OwnerInfoCard(),
              const SizedBox(height: 22),
              const Text(
                '모집 상태 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C3C3C),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _statuses
                    .map(
                      (status) => StatusToggle(
                        isSelected: _selectedStatus == status,
                        text: status,
                        onTap: () {
                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              CustomInputField(
                label: '제목',
                controller: widget.titleController,
                hintText: '한강 공원 시티런 초보 환영',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: '모집 인원',
                      controller: widget.membersController,
                      hintText: '4명',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(Icons.groups_rounded, color: Color(0xFFB33010)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomInputField(
                      label: '시작 시간',
                      controller: widget.startTimeController,
                      hintText: '오후 8:00',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFB33010)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              CustomInputField(
                label: '위치',
                controller: widget.locationController,
                hintText: '성수역 3번 출구',
                suffixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFB33010)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFB33010), Color(0xFFF7673B)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FilledButton(
                    onPressed: widget.onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('글쓰기 완료'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREATE ROOM',
                style: TextStyle(
                  fontSize: 26 / 2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8F2E1A),
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '새로운 러닝 모집',
                style: TextStyle(
                  fontSize: 24 / 1.2,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF262626),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: const Color(0xFFF1F1F1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onClose ?? () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.close_rounded, size: 26, color: Color(0xFF3C3C3C)),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  const _OwnerInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE7D6C6),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF8C6A4A)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '방장',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7D7D7D),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '바통 user1',
                  style: TextStyle(
                    fontSize: 28 / 2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 15, color: Color(0xFFB33010)),
                SizedBox(width: 5),
                Text(
                  'Official',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB33010),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
