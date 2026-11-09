import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: '멤버',
        description: '${s.homeName}에 접근할 수 있는 사람 ${s.members.length}명',
        actions: [FilledButton.icon(onPressed: () => _invite(context), icon: const Icon(Icons.person_add_alt_rounded, size: 18), label: const Text('멤버 초대'))],
      ),
      Panel(
        padding: EdgeInsets.zero,
        child: AdminTable(
          columns: const ['이름', '이메일', '권한', '마지막 활동', '상태'],
          flex: const [16, 20, 12, 10, 10],
          rows: [
            for (final m in s.members)
              [
                Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AdminTokens.accent.withValues(alpha: 0.12),
                    child: Text(m.name.characters.first, style: const TextStyle(color: AdminTokens.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Text(m.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                ]),
                Text(m.email, style: TextStyle(color: t.textSub)),
                m.role == MemberRole.owner
                    ? Text(m.role.label, style: TextStyle(color: t.text, fontWeight: FontWeight.w600))
                    : FilterDropdown<MemberRole>(
                        label: '권한',
                        value: m.role,
                        items: {for (final r in MemberRole.values.where((r) => r != MemberRole.owner)) r: r.label},
                        onChanged: (r) => s.setMemberRole(m, r),
                      ),
                Text(timeAgo(m.lastActive), style: TextStyle(color: t.textMuted, fontSize: 13)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Switch(value: m.active, onChanged: m.role == MemberRole.owner ? null : (_) => s.toggleMember(m)),
                  const SizedBox(width: 4),
                  Text(m.active ? '활성' : '비활성', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
                ]),
              ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Panel(
        title: '권한 안내',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (role, desc) in const [
            ('소유자', '모든 권한 · 장소 삭제 및 소유권 이전'),
            ('관리자', '기기·자동화·멤버 관리'),
            ('멤버', '기기 제어 및 자동화 실행'),
            ('게스트', '지정된 기기만 제어'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(width: 80, child: Text(role, style: TextStyle(fontWeight: FontWeight.w700, color: t.text))),
                Text(desc, style: TextStyle(color: t.textSub)),
              ]),
            ),
        ]),
      ),
    ]);
  }

  void _invite(BuildContext context) {
    final name = TextEditingController();
    final email = TextEditingController();
    var role = MemberRole.member;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('멤버 초대'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: '이름')),
              const SizedBox(height: 12),
              TextField(controller: email, decoration: const InputDecoration(labelText: '이메일')),
              const SizedBox(height: 12),
              DropdownButtonFormField<MemberRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: '권한'),
                items: [for (final r in MemberRole.values.where((r) => r != MemberRole.owner)) DropdownMenuItem(value: r, child: Text(r.label))],
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || !email.text.contains('@')) return;
                HomeStore.instance.inviteMember(name.text.trim(), email.text.trim(), role);
                Navigator.pop(context);
              },
              child: const Text('초대'),
            ),
          ],
        ),
      ),
    );
  }
}
