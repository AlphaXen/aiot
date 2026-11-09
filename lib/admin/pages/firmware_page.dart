import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class FirmwarePage extends StatelessWidget {
  const FirmwarePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    final outdated = s.devices.where((d) => d.firmware != HomeStore.latestFirmware).toList();
    final upToDate = s.devices.length - outdated.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: '펌웨어',
        description: '최신 버전 ${HomeStore.latestFirmware}',
        actions: [
          FilledButton.icon(
            onPressed: outdated.where((d) => d.online).isEmpty
                ? null
                : () {
                    for (final d in outdated.where((d) => d.online)) {
                      s.updateFirmware(d);
                    }
                  },
            icon: const Icon(Icons.system_update_alt_rounded, size: 18),
            label: const Text('온라인 기기 모두 업데이트'),
          ),
        ],
      ),
      ResponsiveGrid(minItemWidth: 230, children: [
        StatTile(label: '최신 버전', value: '$upToDate', unit: '대', icon: Icons.verified_outlined, iconColor: AdminTokens.good),
        StatTile(label: '업데이트 필요', value: '${outdated.length}', unit: '대', icon: Icons.update_rounded, iconColor: AdminTokens.warning),
        StatTile(
          label: '업데이트 불가 (오프라인)',
          value: '${outdated.where((d) => !d.online).length}',
          unit: '대',
          icon: Icons.wifi_off_rounded,
          iconColor: AdminTokens.critical,
        ),
      ]),
      const SizedBox(height: 16),
      Panel(
        title: '업데이트 대상',
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: AdminTable(
          columns: const ['기기', '방', '현재 버전', '최신 버전', '연결', ''],
          flex: const [20, 10, 10, 10, 10, 10],
          emptyText: '모든 기기가 최신 버전입니다 🎉',
          rows: [
            for (final d in outdated)
              [
                Row(children: [
                  DeviceAvatar(type: d.type, size: 30),
                  const SizedBox(width: 10),
                  Flexible(child: Text(d.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.text), overflow: TextOverflow.ellipsis)),
                ]),
                Text(s.roomOf(d).name, style: TextStyle(color: t.textSub)),
                Text(d.firmware, style: const TextStyle(color: AdminTokens.warning, fontWeight: FontWeight.w700)),
                Text(HomeStore.latestFirmware, style: TextStyle(color: t.textSub)),
                StatusBadge.online(d.online),
                OutlinedButton(onPressed: d.online ? () => s.updateFirmware(d) : null, child: const Text('업데이트')),
              ],
          ],
        ),
      ),
    ]);
  }
}
