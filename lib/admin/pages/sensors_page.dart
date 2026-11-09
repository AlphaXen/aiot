import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  String _restaurant = 'all';
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final a = AdminStore.instance;
    final st = RestaurantStore.instance;
    final offline = a.sensors.where((s) => !s.online).length;
    final lowBattery = a.sensors.where((s) => (s.battery ?? 100) < 20).length;
    final outdated = a.sensors.where((s) => s.firmware != AdminStore.latestFirmware).toList();
    final list = a.sensors.where((s) {
      if (_restaurant != 'all' && s.restaurantId != _restaurant) return false;
      if (_status == 'online' && !s.online) return false;
      if (_status == 'offline' && s.online) return false;
      if (_status == 'battery' && (s.battery ?? 100) >= 20) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'IoT 센서',
          description: '출입 카운터 · 좌석 센서 · 카메라 값으로 식당 혼잡도를 계산합니다',
          actions: [
            OutlinedButton.icon(
              onPressed: outdated.isEmpty
                  ? null
                  : () {
                      for (final s in outdated) {
                        a.updateFirmware(s);
                      }
                      toast(context, '센서 ${outdated.length}개 펌웨어를 ${AdminStore.latestFirmware}로 업데이트했어요');
                    },
              icon: const Icon(Icons.system_update_alt_rounded, size: 18),
              label: Text(outdated.isEmpty ? '펌웨어 최신' : '펌웨어 일괄 업데이트 (${outdated.length})'),
            ),
          ],
        ),
        ResponsiveGrid(
          minItemWidth: 220,
          children: [
            StatTile(label: '전체 센서', value: '${a.sensors.length}', unit: '개', icon: Icons.sensors_rounded),
            StatTile(
              label: '연결됨',
              value: '${a.onlineSensors}',
              unit: '/ ${a.sensors.length}',
              icon: Icons.wifi_rounded,
              iconColor: AdminTokens.good,
              footnote: offline == 0
                  ? const StatusBadge(label: '모두 정상', color: AdminTokens.good, icon: Icons.check_circle_rounded)
                  : StatusBadge(label: '끊김 $offline개', color: AdminTokens.critical, icon: Icons.cancel_rounded),
            ),
            StatTile(
              label: '배터리 부족',
              value: '$lowBattery',
              unit: '개',
              icon: Icons.battery_alert_rounded,
              iconColor: AdminTokens.warning,
              footnote: Text('20% 미만', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
            ),
            StatTile(
              label: '최신 펌웨어',
              value: '${a.sensors.length - outdated.length}',
              unit: '/ ${a.sensors.length}',
              icon: Icons.memory_rounded,
              iconColor: AdminTokens.ai,
              footnote: Text('최신 버전 ${AdminStore.latestFirmware}', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterDropdown<String>(
              label: '식당',
              value: _restaurant,
              items: {'all': '모든 식당', for (final r in st.restaurants) r.id: r.name},
              onChanged: (v) => setState(() => _restaurant = v),
            ),
            FilterDropdown<String>(
              label: '상태',
              value: _status,
              items: const {'all': '모든 상태', 'online': '연결됨', 'offline': '연결 끊김', 'battery': '배터리 부족'},
              onChanged: (v) => setState(() => _status = v),
            ),
            Text('${list.length}개 표시', style: TextStyle(color: t.textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          padding: EdgeInsets.zero,
          child: HScroll(
            minWidth: 1000,
            child: AdminTable(
              columns: const ['센서', '식당', '종류', '연결', '배터리', '펌웨어', '마지막 신호', ''],
              flex: const [22, 11, 12, 10, 13, 10, 11, 12],
              emptyText: '조건에 맞는 센서가 없습니다',
              rows: [
                for (final s in list)
                  [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AdminTokens.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.kind.icon, size: 18, color: AdminTokens.accent),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            s.name,
                            style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                          ),
                        ),
                      ],
                    ),
                    Text(st.byId(s.restaurantId).name, style: TextStyle(color: t.textSub, fontSize: 13)),
                    Text(s.kind.label, style: TextStyle(color: t.textSub, fontSize: 13)),
                    s.online
                        ? const StatusBadge(label: '연결됨', color: AdminTokens.good, icon: Icons.check_circle_rounded)
                        : const StatusBadge(label: '끊김', color: AdminTokens.critical, icon: Icons.cancel_rounded),
                    _Battery(value: s.battery),
                    Text(
                      s.firmware,
                      style: TextStyle(
                        fontSize: 13,
                        color: s.firmware == AdminStore.latestFirmware ? t.textSub : AdminTokens.warning,
                        fontWeight: s.firmware == AdminStore.latestFirmware ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    Text(timeAgo(s.lastSeen), style: TextStyle(color: t.textMuted, fontSize: 13)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!s.online)
                          TextButton(onPressed: () => a.reconnect(s), child: const Text('재연결'))
                        else if ((s.battery ?? 100) < 20)
                          TextButton(onPressed: () => a.replaceBattery(s), child: const Text('배터리 교체'))
                        else if (s.firmware != AdminStore.latestFirmware)
                          TextButton(onPressed: () => a.updateFirmware(s), child: const Text('업데이트')),
                      ],
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

class _Battery extends StatelessWidget {
  const _Battery({required this.value});
  final int? value;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final v = value;
    if (v == null) return Text('전원 연결', style: TextStyle(color: t.textMuted, fontSize: 13));
    final color = v < 20 ? AdminTokens.critical : (v < 50 ? AdminTokens.warning : AdminTokens.good);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: v / 100, minHeight: 8, color: color, backgroundColor: t.grid),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$v%',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: v < 20 ? color : t.text),
        ),
      ],
    );
  }
}
