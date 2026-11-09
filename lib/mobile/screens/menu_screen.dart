import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../mobile_theme.dart';
import 'home_shell.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    Widget group(List<(IconData, String, String?)> items) => Card(
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Icon(items[i].$1),
                title: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: items[i].$3 == null
                    ? Icon(Icons.chevron_right_rounded, color: context.subtle)
                    : Text(items[i].$3!, style: TextStyle(color: context.subtle)),
                onTap: () {},
              ),
              if (i < items.length - 1) Divider(height: 1, indent: 56, color: context.isDark ? Colors.white10 : Colors.black12),
            ],
          ]),
        );

    return CustomScrollView(slivers: [
      const LargeHeader(title: '메뉴'),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.list(children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(radius: 24, backgroundColor: MobileColors.accent, child: Text('홍', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              title: Text(store.members.first.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: Text(store.members.first.email),
              trailing: Icon(Icons.chevron_right_rounded, color: context.subtle),
            ),
          ),
          const SizedBox(height: 12),
          group([
            (Icons.home_outlined, '장소 관리', store.homeName),
            (Icons.meeting_room_outlined, '방 관리', '${store.rooms.length}개'),
            (Icons.group_outlined, '멤버', '${store.members.length}명'),
          ]),
          const SizedBox(height: 12),
          group([
            (Icons.history_rounded, '활동 기록', null),
            (Icons.notifications_none_rounded, '알림 설정', null),
            (Icons.settings_outlined, '설정', null),
            (Icons.help_outline_rounded, '도움말', null),
          ]),
          const SizedBox(height: 24),
          Center(child: Text('AIoT Home v1.0.0', style: TextStyle(color: context.subtle, fontSize: 12))),
          const SizedBox(height: 24),
        ]),
      ),
    ]);
  }
}
