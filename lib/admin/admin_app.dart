import 'package:flutter/material.dart';

import '../shared/restaurant.dart';
import 'admin_store.dart';
import 'admin_theme.dart';
import 'pages/ai_settings_page.dart';
import 'pages/logs_page.dart';
import 'pages/menus_page.dart';
import 'pages/overview_page.dart';
import 'pages/restaurants_page.dart';
import 'pages/sensors_page.dart';
import 'pages/stats_page.dart';

/// PC용 관리자 대시보드 (캠퍼스 식당 혼잡도 관리)
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '캠퍼스 식당 관리자',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(Brightness.light),
      darkTheme: buildAdminTheme(Brightness.dark),
      themeMode: _mode,
      home: AdminShell(onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark)),
    );
  }
}

/// 사이드바 메뉴 순서 (페이지 이동용 인덱스)
abstract final class AdminNav {
  static const overview = 0, restaurants = 1, menus = 2, sensors = 3, ai = 4, stats = 5, logs = 6;
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.builder);
  final IconData icon;
  final String label;
  final Widget Function(void Function(int) go) builder;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<_NavItem> _items = [
    _NavItem(Icons.space_dashboard_outlined, '대시보드', (go) => OverviewPage(onNavigate: go)),
    _NavItem(Icons.storefront_outlined, '식당 · 혼잡도', (_) => const RestaurantsPage()),
    _NavItem(Icons.restaurant_menu_rounded, '메뉴 관리', (_) => const MenusPage()),
    _NavItem(Icons.sensors_rounded, 'IoT 센서', (_) => const SensorsPage()),
    _NavItem(Icons.auto_awesome_outlined, 'AI 추천 설정', (_) => const AiSettingsPage()),
    _NavItem(Icons.insights_rounded, '이용 통계', (_) => const StatsPage()),
    _NavItem(Icons.receipt_long_outlined, '활동 로그', (_) => const LogsPage()),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final sidebar = _Sidebar(
      items: _items,
      index: _index,
      onSelect: (i) {
        _go(i);
        if (!wide) Navigator.of(context).maybePop();
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide ? null : Drawer(backgroundColor: t.panel, width: 260, child: sidebar),
      body: Row(
        children: [
          if (wide) SizedBox(width: 248, child: sidebar),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  showMenu: !wide,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onToggleTheme: widget.onToggleTheme,
                  onOpenLogs: () => _go(AdminNav.logs),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([RestaurantStore.instance, AdminStore.instance]),
                    builder: (context, _) => SingleChildScrollView(
                      padding: EdgeInsets.all(wide ? 32 : 16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: KeyedSubtree(key: ValueKey(_index), child: _items[_index].builder(_go)),
                        ),
                      ),
                    ),
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.items, required this.index, required this.onSelect});
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final a = AdminStore.instance;
    return Container(
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(right: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8A2A), Color(0xFFE85D04)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '캠퍼스 식당',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: t.text),
                        ),
                        Text('관리자 콘솔', style: TextStyle(fontSize: 11.5, color: t.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Material(
                  color: i == index ? AdminTokens.accent.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    hoverColor: t.hover,
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(items[i].icon, size: 20, color: i == index ? AdminTokens.accent : t.textSub),
                          const SizedBox(width: 12),
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? AdminTokens.accent : t.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListenableBuilder(
                listenable: a,
                builder: (context, _) {
                  final allOk = a.onlineSensors == a.sensors.length;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: t.canvas, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.sensors_rounded, size: 20, color: t.textSub),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '센서 ${a.onlineSensors}/${a.sensors.length} 연결',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
                              ),
                              Text(
                                allOk ? '모두 정상' : '${a.sensors.length - a.onlineSensors}개 연결 끊김',
                                style: TextStyle(fontSize: 11.5, color: t.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          allOk ? Icons.check_circle_rounded : Icons.error_rounded,
                          size: 16,
                          color: allOk ? AdminTokens.good : AdminTokens.critical,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showMenu, required this.onMenu, required this.onToggleTheme, required this.onOpenLogs});
  final bool showMenu;
  final VoidCallback onMenu, onToggleTheme, onOpenLogs;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final a = AdminStore.instance;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          if (showMenu) IconButton(tooltip: '메뉴', icon: const Icon(Icons.menu_rounded), onPressed: onMenu),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 18, color: t.textSub),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '본캠퍼스',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: t.text),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, size: 18, color: t.textMuted),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width > 480)
            IconButton(
              tooltip: '혼잡도 새로고침',
              icon: Icon(Icons.refresh_rounded, color: t.textSub),
              onPressed: RestaurantStore.instance.refresh,
            ),
          IconButton(
            tooltip: dark ? '라이트 모드' : '다크 모드',
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.textSub),
            onPressed: onToggleTheme,
          ),
          ListenableBuilder(
            listenable: a,
            builder: (context, _) => IconButton(
              tooltip: '알림',
              onPressed: onOpenLogs,
              icon: Badge(
                isLabelVisible: a.alertCount > 0,
                label: Text('${a.alertCount}'),
                child: Icon(Icons.notifications_none_rounded, color: t.textSub),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 17,
            backgroundColor: AdminTokens.accent,
            child: Text(
              '김',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 640) ...[
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AdminStore.adminName,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: t.text),
                ),
                Text(AdminStore.adminRole, style: TextStyle(fontSize: 11.5, color: t.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
