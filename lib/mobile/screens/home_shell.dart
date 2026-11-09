import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../mobile_theme.dart';
import 'automation_screen.dart';
import 'devices_screen.dart';
import 'favorites_screen.dart';
import 'life_screen.dart';
import 'menu_screen.dart';

/// 하단 탭 5개: 즐겨찾기 · 기기 · 라이프 · 자동화 · 메뉴
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (Icons.star_outline_rounded, Icons.star_rounded, '즐겨찾기'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, '기기'),
    (Icons.eco_outlined, Icons.eco_rounded, '라이프'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, '자동화'),
    (Icons.menu_rounded, Icons.menu_rounded, '메뉴'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HomeStore.instance,
      builder: (context, _) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [FavoritesScreen(), DevicesScreen(), LifeScreen(), AutomationScreen(), MenuScreen()],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.isDark ? MobileColors.darkBg : MobileColors.lightBg,
            border: Border(top: BorderSide(color: context.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: InkResponse(
                        onTap: () => setState(() => _index = i),
                        radius: 36,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(i == _index ? _tabs[i].$2 : _tabs[i].$1,
                                size: 25, color: i == _index ? (context.isDark ? Colors.white : Colors.black) : context.subtle),
                            const SizedBox(height: 3),
                            Text(
                              _tabs[i].$3,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500,
                                color: i == _index ? (context.isDark ? Colors.white : Colors.black) : context.subtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One UI 스타일의 큰 제목 헤더 (위치 이름 + 우측 아이콘)
class LargeHeader extends StatelessWidget {
  const LargeHeader({super.key, required this.title, this.showLocation = false, this.actions = const []});
  final String title;
  final bool showLocation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLocation)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(HomeStore.instance.homeName, style: TextStyle(fontSize: 14, color: context.subtle, fontWeight: FontWeight.w600)),
                        Icon(Icons.expand_more_rounded, size: 18, color: context.subtle),
                      ]),
                    Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 16, 10),
        child: Row(children: [
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          ?trailing,
        ]),
      ),
    );
  }
}
