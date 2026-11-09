import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  LogLevel? _level;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    final logs = s.logs.where((l) {
      if (_level != null && l.level != _level) return false;
      if (_query.isNotEmpty && !'${l.deviceName} ${l.message} ${l.actor}'.contains(_query)) return false;
      return true;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: '활동 로그', description: '기기 제어, 자동화 실행, 시스템 이벤트 기록'),
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: '기기, 내용, 사용자 검색', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        SegmentedButton<LogLevel?>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: null, label: Text('전체')),
            ButtonSegment(value: LogLevel.info, label: Text('정보')),
            ButtonSegment(value: LogLevel.warning, label: Text('경고')),
            ButtonSegment(value: LogLevel.error, label: Text('오류')),
          ],
          selected: {_level},
          onSelectionChanged: (v) => setState(() => _level = v.first),
        ),
        Text('${logs.length}건', style: TextStyle(color: t.textMuted, fontSize: 13)),
      ]),
      const SizedBox(height: 16),
      Panel(
        padding: EdgeInsets.zero,
        child: AdminTable(
          columns: const ['시간', '수준', '대상', '내용', '실행 주체'],
          flex: const [12, 8, 14, 24, 8],
          emptyText: '조건에 맞는 로그가 없습니다',
          rows: [
            for (final l in logs.take(100))
              [
                Text(ymdhm(l.time), style: TextStyle(color: t.textMuted, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
                StatusBadge.log(l.level),
                Text(l.deviceName, style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                Text(l.message, style: TextStyle(color: t.textSub)),
                Text(l.actor, style: TextStyle(color: t.textSub)),
              ],
          ],
        ),
      ),
    ]);
  }
}
