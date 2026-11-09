import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../mobile_theme.dart';
import 'home_shell.dart';

/// 자동화(루틴) 목록 + 장면 목록
class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => CustomScrollView(
        slivers: [
          LargeHeader(
            title: '자동화',
            showLocation: true,
            actions: [
              IconButton(tooltip: '자동화 추가', icon: const Icon(Icons.add_rounded, size: 28), onPressed: () => _addRoutine(context)),
            ],
          ),
          SectionTitle('루틴 ${store.routines.length}'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: store.routines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _RoutineCard(routine: store.routines[i]),
            ),
          ),
          const SectionTitle('장면'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: store.scenes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = store.scenes[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                    leading: CircleAvatar(backgroundColor: s.color.withValues(alpha: 0.15), child: Icon(s.icon, color: s.color)),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('기기 ${s.actions.length}개 제어'),
                    trailing: IconButton.filledTonal(
                      tooltip: '실행',
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        store.runScene(s);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text('"${s.name}" 장면을 실행했어요'), behavior: SnackBarBehavior.floating));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _addRoutine(BuildContext context) {
    final name = TextEditingController();
    final trigger = TextEditingController();
    final action = TextEditingController();
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: context.inactiveFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('새 루틴', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: deco('이름 (예: 퇴근길 냉방)')),
          const SizedBox(height: 10),
          TextField(controller: trigger, decoration: deco('조건 — 만약 (예: 평일 오후 6:30)')),
          const SizedBox(height: 10),
          TextField(controller: action, decoration: deco('동작 — 그러면 (예: 거실 에어컨 켜기)')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
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
              child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final r = routine;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _line(context, '만약', r.trigger),
              const SizedBox(height: 4),
              _line(context, '그러면', r.action),
            ]),
          ),
          Switch(value: r.enabled, onChanged: (_) => HomeStore.instance.toggleRoutine(r)),
        ]),
      ),
    );
  }

  Widget _line(BuildContext context, String k, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 44, child: Text(k, style: const TextStyle(fontSize: 13, color: MobileColors.accent, fontWeight: FontWeight.w700))),
        Expanded(child: Text(v, style: TextStyle(fontSize: 13.5, color: context.subtle))),
      ]);
}
