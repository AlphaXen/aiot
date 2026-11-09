import 'package:flutter/material.dart';

import '../shared/home_store.dart';
import 'admin_theme.dart';
import 'pages/automations_page.dart';
import 'pages/devices_page.dart';
import 'pages/firmware_page.dart';
import 'pages/locations_page.dart';
import 'pages/logs_page.dart';
import 'pages/members_page.dart';
import 'pages/overview_page.dart';

/// PC용 관리자 대시보드
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
      title: 'AIoT Console',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(Brightness.light),
      darkTheme: buildAdminTheme(Brightness.dark),
      themeMode: _mode,
      home: AdminShell(
        onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      ),
    );
  }
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
    _NavItem(Icons.devices_other_outlined, '기기', (_) => const DevicesPage()),
    _NavItem(Icons.location_on_outlined, '장소 · 방', (_) => const LocationsPage()),
    _NavItem(Icons.auto_awesome_outlined, '자동화', (_) => const AutomationsPage()),
    _NavItem(Icons.group_outlined, '멤버', (_) => const MembersPage()),
    _NavItem(Icons.receipt_long_outlined, '활동 로그', (_) => const LogsPage()),
    _NavItem(Icons.system_update_alt_rounded, '펌웨어', (_) => const FirmwarePage()),
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
      body: Row(children: [
        if (wide) SizedBox(width: 248, child: sidebar),
        Expanded(
          child: Column(children: [
            _TopBar(
              showMenu: !wide,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onToggleTheme: widget.onToggleTheme,
              onOpenLogs: () => _go(5),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: HomeStore.instance,
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
          ]),
        ),
      ]),
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
    return Container(
      decoration: BoxDecoration(color: t.panel, border: Border(right: BorderSide(color: t.border))),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3E91FF), Color(0xFF1C6BE8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AIoT Console',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: t.text)),
                  Text('관리자', style: TextStyle(fontSize: 11.5, color: t.textMuted)),
                ]),
              ),
            ]),
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
                    child: Row(children: [
                      Icon(items[i].icon, size: 20, color: i == index ? AdminTokens.accent : t.textSub),
                      const SizedBox(width: 12),
                      Text(items[i].label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                            color: i == index ? AdminTokens.accent : t.textSub,
                          )),
                    ]),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: t.canvas, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.router_outlined, size: 20, color: t.textSub),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('허브 연결됨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                    Text('Hub-01 · 지연 24ms', style: TextStyle(fontSize: 11.5, color: t.textMuted)),
                  ]),
                ),
                const Icon(Icons.check_circle_rounded, size: 16, color: AdminTokens.good),
              ]),
            ),
          ),
        ]),
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
    final store = HomeStore.instance;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: t.panel, border: Border(bottom: BorderSide(color: t.border))),
      child: Row(children: [
        if (showMenu) IconButton(tooltip: '메뉴', icon: const Icon(Icons.menu_rounded), onPressed: onMenu),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: t.border), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.home_outlined, size: 18, color: t.textSub),
            const SizedBox(width: 6),
            Text(store.homeName, style: TextStyle(fontWeight: FontWeight.w600, color: t.text)),
            Icon(Icons.expand_more_rounded, size: 18, color: t.textMuted),
          ]),
        ),
        const Spacer(),
        IconButton(
          tooltip: dark ? '라이트 모드' : '다크 모드',
          icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.textSub),
          onPressed: onToggleTheme,
        ),
        ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final alerts = store.logs.where((l) => l.level.index > 0).length;
            return IconButton(
              tooltip: '알림',
              onPressed: onOpenLogs,
              icon: Badge(
                isLabelVisible: alerts > 0,
                label: Text('$alerts'),
                child: Icon(Icons.notifications_none_rounded, color: t.textSub),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        const CircleAvatar(radius: 17, backgroundColor: AdminTokens.accent, child: Text('홍', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
        if (MediaQuery.sizeOf(context).width > 640) ...[
          const SizedBox(width: 10),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(store.members.first.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: t.text)),
            Text(store.members.first.role.label, style: TextStyle(fontSize: 11.5, color: t.textMuted)),
          ]),
        ],
      ]),
    );
  }
}
