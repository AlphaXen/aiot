import 'package:flutter/material.dart';

import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String _level = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final a = AdminStore.instance;
    final list = a.logs.where((l) {
      if (_level != 'all' && l.level.name != _level) return false;
      if (_query.isNotEmpty && !'${l.target} ${l.message}'.contains(_query)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(title: '활동 로그', description: '혼잡도 경보 · 센서 상태 · 메뉴 변경 등 기록 ${a.logs.length}건'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(hintText: '식당 · 센서 · 내용 검색', prefixIcon: Icon(Icons.search_rounded, size: 20)),
              ),
            ),
            FilterDropdown<String>(
              label: '수준',
              value: _level,
              items: {'all': '모든 수준', for (final l in LogLevel.values) l.name: l.label},
              onChanged: (v) => setState(() => _level = v),
            ),
            Text('${list.length}건 표시', style: TextStyle(color: t.textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          padding: EdgeInsets.zero,
          child: HScroll(
            minWidth: 760,
            child: AdminTable(
              columns: const ['수준', '대상', '내용', '처리자', '시간'],
              flex: const [9, 18, 40, 10, 10],
              emptyText: '조건에 맞는 기록이 없습니다',
              rows: [
                for (final l in list)
                  [
                    StatusBadge.log(l.level),
                    Text(
                      l.target,
                      style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                    ),
                    Text(l.message, style: TextStyle(color: t.textSub)),
                    Text(l.actor, style: TextStyle(color: t.textSub, fontSize: 13)),
                    Tooltip(
                      message: l.time.toString().substring(0, 16),
                      child: Text(timeAgo(l.time), style: TextStyle(color: t.textMuted, fontSize: 13)),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
