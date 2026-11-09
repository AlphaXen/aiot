import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';
import 'home_screen.dart';
import 'home_shell.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _notifyRelaxed = true;
  bool _notifyLunch = false;

  @override
  Widget build(BuildContext context) {
    final store = RestaurantStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final favs = store.restaurants.where((r) => r.favorite).toList();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: MobileColors.accent.withValues(alpha: 0.15),
                      child: const Icon(Icons.person_rounded, size: 34, color: MobileColors.accent),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('게스트', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                        Text('로그인하면 즐겨찾기가 저장돼요', style: TextStyle(color: context.subtle, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SectionTitle('즐겨찾는 식당 ${favs.length}'),
            if (favs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 32, color: context.subtle),
                        const SizedBox(height: 8),
                        Text('식당 상세에서 ♡를 눌러 추가해 보세요', style: TextStyle(color: context.subtle)),
                      ],
                    ),
                  ),
                ),
              )
            else
              for (final r in favs)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: RestaurantCard(restaurant: r),
                ),
            const SectionTitle('알림'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('즐겨찾기 식당이 여유로워지면 알림', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: _notifyRelaxed,
                      onChanged: (v) => setState(() => _notifyRelaxed = v),
                    ),
                    SwitchListTile(
                      title: const Text('점심시간 AI 추천 알림', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('매일 11:30'),
                      value: _notifyLunch,
                      onChanged: (v) => setState(() => _notifyLunch = v),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('앱 정보'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('버전'),
                      trailing: Text('1.0.0 (개발)', style: TextStyle(color: context.subtle)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sensors_rounded),
                      title: const Text('혼잡도 측정 방식'),
                      subtitle: const Text('식당 내 IoT 센서로 좌석 사용률을 측정해요'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
