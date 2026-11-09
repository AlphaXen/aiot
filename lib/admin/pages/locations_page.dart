import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';
import 'devices_page.dart';

class LocationsPage extends StatelessWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(title: '장소 · 방', description: '${s.homeName} · 방 ${s.rooms.length}개'),
      ResponsiveGrid(minItemWidth: 320, children: [
        for (final r in s.rooms)
          Builder(builder: (context) {
            final ds = s.devicesIn(r.id);
            final offline = ds.where((d) => !d.online).length;
            final watts = ds.where((d) => d.online && d.isOn).fold(0.0, (a, d) => a + d.powerWatts);
            return Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: AdminTokens.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(r.icon, color: AdminTokens.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.text)),
                      Text('기기 ${ds.length}대 · ${watts.toStringAsFixed(0)}W 사용 중', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
                    ]),
                  ),
                  if (offline > 0)
                    StatusBadge(label: '오프라인 $offline', color: AdminTokens.critical, icon: Icons.cancel_rounded)
                  else
                    const StatusBadge(label: '정상', color: AdminTokens.good, icon: Icons.check_circle_rounded),
                ]),
                const SizedBox(height: 14),
                Divider(height: 1, color: t.border),
                const SizedBox(height: 6),
                for (final d in ds)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: t.hover,
                    onTap: () => showDeviceDialog(context, d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                      child: Row(children: [
                        DeviceAvatar(type: d.type, size: 28),
                        const SizedBox(width: 10),
                        Expanded(child: Text(d.name, style: TextStyle(color: t.text, fontSize: 13.5))),
                        Text(d.statusText, style: TextStyle(fontSize: 12.5, color: d.online ? t.textMuted : AdminTokens.critical)),
                      ]),
                    ),
                  ),
                if (ds.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('기기 없음', style: TextStyle(color: t.textMuted))),
              ]),
            );
          }),
      ]),
    ]);
  }
}
