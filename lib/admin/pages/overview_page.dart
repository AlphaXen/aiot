import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../admin_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.onNavigate});
  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    final offline = s.devices.where((d) => !d.online).toList();
    final lowBattery = s.devices.where((d) => (d.batteryPercent ?? 100) < 20).toList();
    final outdated = s.devices.where((d) => d.firmware != HomeStore.latestFirmware).length;
    final weekTotal = s.weeklyEnergy.fold(0.0, (a, b) => a + b);
    final now = DateTime.now();
    final dayLabels = [for (var i = 6; i >= 0; i--) _dow(now.subtract(Duration(days: i)))];
    dayLabels[6] = '오늘';

    final byType = <DeviceType, int>{};
    for (final d in s.devices) {
      byType[d.type] = (byType[d.type] ?? 0) + 1;
    }
    final typeItems = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final energyByRoom = [
      for (final r in s.rooms)
        (r.name, r.icon as IconData?, s.devicesIn(r.id).where((d) => d.online && d.isOn).fold(0.0, (a, d) => a + d.powerWatts)),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: '대시보드',
        description: '${s.homeName}의 기기 상태와 사용량을 한눈에 확인하세요',
        actions: [
          OutlinedButton.icon(onPressed: () => onNavigate(5), icon: const Icon(Icons.receipt_long_outlined, size: 18), label: const Text('로그 보기')),
          FilledButton.icon(onPressed: () => onNavigate(1), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('기기 관리')),
        ],
      ),
      ResponsiveGrid(minItemWidth: 230, children: [
        StatTile(
          label: '전체 기기',
          value: '${s.devices.length}',
          unit: '대',
          icon: Icons.devices_other_outlined,
          footnote: Text('방 ${s.rooms.length}개에 설치', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
        ),
        StatTile(
          label: '온라인',
          value: '${s.onlineCount}',
          unit: '/ ${s.devices.length}',
          icon: Icons.wifi_rounded,
          iconColor: AdminTokens.good,
          footnote: offline.isEmpty
              ? const StatusBadge(label: '모두 정상', color: AdminTokens.good, icon: Icons.check_circle_rounded)
              : StatusBadge(label: '오프라인 ${offline.length}대', color: AdminTokens.critical, icon: Icons.cancel_rounded),
        ),
        StatTile(
          label: '현재 소비 전력',
          value: (s.currentPowerWatts / 1000).toStringAsFixed(2),
          unit: 'kW',
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFB7791F),
          footnote: Text('작동 중 ${s.activeCount}대', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
        ),
        StatTile(
          label: '활성 자동화',
          value: '${s.routines.where((r) => r.enabled).length}',
          unit: '/ ${s.routines.length}',
          icon: Icons.auto_awesome_outlined,
          iconColor: const Color(0xFF6250D6),
          footnote: Text('장면 ${s.scenes.length}개', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
        ),
      ]),
      const SizedBox(height: 16),
      _TwoCol(
        left: Panel(
          title: '에너지 사용량',
          subtitle: '최근 7일 · 합계 ${weekTotal.toStringAsFixed(1)} kWh',
          child: BarChart(values: s.weeklyEnergy, labels: dayLabels, unit: 'kWh'),
        ),
        right: Panel(
          title: '방별 현재 전력',
          subtitle: '작동 중인 기기 기준 (W)',
          child: HorizontalBars(items: energyByRoom, unit: 'W'),
        ),
      ),
      const SizedBox(height: 16),
      _TwoCol(
        left: Panel(
          title: '실내 평균 온도',
          subtitle: '최근 24시간 · 온습도 센서 평균',
          child: LineChart(
            values: s.hourlyTemperature,
            unit: '°C',
            xLabel: (i) => '${(now.hour - 23 + i) % 24}시', // Dart의 %는 음수에도 0~23을 돌려줍니다
          ),
        ),
        right: Panel(
          title: '유형별 기기',
          child: HorizontalBars(items: [for (final e in typeItems) (e.key.label, e.key.icon, e.value.toDouble())], unit: '대'),
        ),
      ),
      const SizedBox(height: 16),
      _TwoCol(
        left: Panel(
          title: '최근 활동',
          trailing: TextButton(onPressed: () => onNavigate(5), child: const Text('전체 보기')),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(children: [
            for (final l in s.logs.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  SizedBox(width: 72, child: StatusBadge.log(l.level)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: l.deviceName, style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                      TextSpan(text: '  ${l.message}', style: TextStyle(color: t.textSub)),
                    ]), overflow: TextOverflow.ellipsis),
                  ),
                  Text('${l.actor} · ${timeAgo(l.time)}', style: TextStyle(fontSize: 12, color: t.textMuted)),
                ]),
              ),
          ]),
        ),
        right: Panel(
          title: '확인 필요',
          subtitle: '조치가 필요한 기기',
          child: Column(children: [
            for (final d in offline)
              _AlertRow(
                icon: Icons.wifi_off_rounded,
                color: AdminTokens.critical,
                title: d.name,
                detail: '오프라인 · ${timeAgo(d.lastSeen)}',
                action: TextButton(onPressed: () => s.reconnect(d), child: const Text('재연결')),
              ),
            for (final d in lowBattery)
              _AlertRow(icon: Icons.battery_alert_rounded, color: AdminTokens.warning, title: d.name, detail: '배터리 ${d.batteryPercent}%'),
            if (outdated > 0)
              _AlertRow(
                icon: Icons.system_update_alt_rounded,
                color: AdminTokens.accent,
                title: '펌웨어 업데이트',
                detail: '$outdated대 업데이트 가능',
                action: TextButton(onPressed: () => onNavigate(6), child: const Text('보기')),
              ),
            if (offline.isEmpty && lowBattery.isEmpty && outdated == 0)
              Padding(padding: const EdgeInsets.all(20), child: Text('모든 기기가 정상입니다', style: TextStyle(color: t.textMuted))),
          ]),
        ),
      ),
    ]);
  }

  static String _dow(DateTime d) => const ['월', '화', '수', '목', '금', '토', '일'][d.weekday - 1];
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.icon, required this.color, required this.title, required this.detail, this.action});
  final IconData icon;
  final Color color;
  final String title, detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: t.text)),
            Text(detail, style: TextStyle(fontSize: 12.5, color: t.textMuted)),
          ]),
        ),
        ?action,
      ]),
    );
  }
}

/// 넓은 화면에서는 3:2 두 칸, 좁으면 세로로 쌓기
class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});
  final Widget left, right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 900) {
        return Column(children: [left, const SizedBox(height: 16), right]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: left),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: right),
      ]);
    });
  }
}
