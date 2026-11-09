import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class AutomationsPage extends StatelessWidget {
  const AutomationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: '자동화',
        description: '루틴 ${s.routines.length}개 · 사용 중 ${s.routines.where((r) => r.enabled).length}개',
        actions: [FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('루틴 추가'))],
      ),
      Panel(
        padding: EdgeInsets.zero,
        child: AdminTable(
          columns: const ['이름', '조건 (만약)', '동작 (그러면)', '마지막 실행', '사용', ''],
          flex: const [14, 20, 24, 10, 6, 10],
          rows: [
            for (final r in s.routines)
              [
                Text(r.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                Text(r.trigger, style: TextStyle(color: t.textSub)),
                Text(r.action, style: TextStyle(color: t.textSub)),
                Text(r.lastRun == null ? '-' : timeAgo(r.lastRun!), style: TextStyle(color: t.textMuted, fontSize: 13)),
                Switch(value: r.enabled, onChanged: (_) => s.toggleRoutine(r, actor: '관리자')),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: '지금 실행', icon: const Icon(Icons.play_arrow_rounded), onPressed: () => s.runRoutine(r)),
                  IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.delete_outline_rounded, color: AdminTokens.critical),
                    onPressed: () => s.removeRoutine(r),
                  ),
                ]),
              ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text('장면', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: t.text)),
      const SizedBox(height: 12),
      ResponsiveGrid(minItemWidth: 240, children: [
        for (final sc in s.scenes)
          Panel(
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: sc.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(sc.icon, color: sc.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sc.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                  Text('기기 ${sc.actions.length}개', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
                ]),
              ),
              OutlinedButton(onPressed: () => s.runScene(sc, actor: '관리자'), child: const Text('실행')),
            ]),
          ),
      ]),
    ]);
  }

  void _add(BuildContext context) {
    final name = TextEditingController();
    final trigger = TextEditingController();
    final action = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 추가'),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: '이름')),
            const SizedBox(height: 12),
            TextField(controller: trigger, decoration: const InputDecoration(labelText: '조건 (예: 매일 오후 10:00)')),
            const SizedBox(height: 12),
            TextField(controller: action, decoration: const InputDecoration(labelText: '동작 (예: 모든 조명 끄기)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              HomeStore.instance.addRoutine(Routine(
                id: 'r${DateTime.now().millisecondsSinceEpoch}',
                name: name.text.trim(),
                trigger: trigger.text.trim().isEmpty ? '수동' : trigger.text.trim(),
                action: action.text.trim().isEmpty ? '-' : action.text.trim(),
              ));
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
