import 'package:flutter/material.dart';

import '../mobile_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'my_screen.dart';

/// 하단 탭 3개: 홈 · 지도 · MY
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, '홈'),
    (Icons.map_outlined, Icons.map_rounded, '지도'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'MY'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // 각 탭이 화면 전체 크기를 받도록 (없으면 지도 탭 Stack이 범례 높이로 줄어듦)
        sizing: StackFit.expand,
        index: _index,
        children: [
          HomeScreen(onOpenMap: () => setState(() => _index = 1)),
          const MapScreen(),
          const MyScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
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
                          Icon(i == _index ? _tabs[i].$2 : _tabs[i].$1, size: 25, color: i == _index ? context.fg : context.subtle),
                          const SizedBox(height: 3),
                          Text(
                            _tabs[i].$3,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500,
                              color: i == _index ? context.fg : context.subtle,
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
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 12, 10),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
