import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../mobile_theme.dart';
import '../widgets/device_tile.dart';
import 'favorites_screen.dart';
import 'home_shell.dart';

/// 방별 필터 칩 + 기기 그리드
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String? _roomId; // null = 전체

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final rooms = _roomId == null ? store.rooms : store.rooms.where((r) => r.id == _roomId).toList();
        return CustomScrollView(
          slivers: [
            LargeHeader(
              title: '기기',
              showLocation: true,
              actions: [
                IconButton(tooltip: '기기 추가', icon: const Icon(Icons.add_rounded, size: 28), onPressed: () => showAddDeviceSheet(context)),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _RoomChip(label: '전체 ${store.devices.length}', selected: _roomId == null, onTap: () => setState(() => _roomId = null)),
                    for (final r in store.rooms)
                      _RoomChip(
                        label: '${r.name} ${store.devicesIn(r.id).length}',
                        selected: _roomId == r.id,
                        onTap: () => setState(() => _roomId = r.id),
                      ),
                  ],
                ),
              ),
            ),
            for (final r in rooms) ...[
              SectionTitle(
                r.name,
                trailing: Text('${store.devicesIn(r.id).where((d) => d.isActive).length}개 작동 중',
                    style: TextStyle(color: context.subtle, fontSize: 13)),
              ),
              DeviceGrid(devices: store.devicesIn(r.id), showRoom: false),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? (context.isDark ? Colors.black : Colors.white) : null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? (context.isDark ? Colors.white : const Color(0xFF1C1C1E)) : context.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
          ),
        ),
      ),
    );
  }
}
