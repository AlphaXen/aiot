import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../mobile_theme.dart';
import '../widgets/device_tile.dart';
import 'home_shell.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final favs = store.favorites;
        return CustomScrollView(
          slivers: [
            LargeHeader(
              title: '즐겨찾기',
              showLocation: true,
              actions: [
                IconButton(tooltip: '기기 추가', icon: const Icon(Icons.add_rounded, size: 28), onPressed: () => showAddDeviceSheet(context)),
                IconButton(tooltip: '알림', icon: const Icon(Icons.notifications_none_rounded, size: 26), onPressed: () => _showNotifications(context)),
              ],
            ),
            SliverToBoxAdapter(child: _SummaryStrip(store: store)),
            const SectionTitle('장면'),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: store.scenes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _SceneCard(scene: store.scenes[i]),
                ),
              ),
            ),
            const SectionTitle('즐겨찾는 기기'),
            if (favs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('기기 상세 화면에서 ☆을 눌러 즐겨찾기에 추가하세요',
                      textAlign: TextAlign.center, style: TextStyle(color: context.subtle)),
                ),
              )
            else
              DeviceGrid(devices: favs),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    final logs = HomeStore.instance.logs.where((l) => l.level != LogLevel.info).take(10).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('알림', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            for (final l in logs)
              ListTile(
                leading: Icon(
                  l.level == LogLevel.error ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  color: l.level == LogLevel.error ? MobileColors.offline : const Color(0xFFFFA000),
                ),
                title: Text(l.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l.message),
                trailing: Text(timeAgo(l.time), style: TextStyle(color: context.subtle, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.store});
  final HomeStore store;

  @override
  Widget build(BuildContext context) {
    final sensor = store.devices.where((d) => d.type == DeviceType.sensor && d.online).firstOrNull;
    final offline = store.devices.length - store.onlineCount;
    Widget item(IconData icon, String value, String label, {Color? color}) => Expanded(
          child: Column(children: [
            Icon(icon, size: 22, color: color ?? context.subtle),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(fontSize: 12, color: context.subtle)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            item(Icons.thermostat_rounded, sensor == null ? '-' : '${sensor.temperature!.toStringAsFixed(1)}°', '실내 온도', color: const Color(0xFFFF7043)),
            item(Icons.water_drop_outlined, sensor == null ? '-' : '${sensor.humidity!.toStringAsFixed(0)}%', '습도', color: const Color(0xFF3E91FF)),
            item(Icons.bolt_rounded, '${(store.currentPowerWatts / 1000).toStringAsFixed(2)}kW', '현재 전력', color: const Color(0xFFFFB300)),
            item(offline > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, '$offline대', '연결 끊김',
                color: offline > 0 ? MobileColors.offline : const Color(0xFF26A65B)),
          ]),
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene});
  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HomeStore.instance.runScene(scene);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('"${scene.name}" 장면을 실행했어요'), behavior: SnackBarBehavior.floating));
        },
        child: Container(
          width: 128,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: scene.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(scene.icon, color: scene.color, size: 20),
              ),
              Row(children: [
                Expanded(child: Text(scene.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                Icon(Icons.play_arrow_rounded, size: 20, color: context.subtle),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기기 추가 시트 (모바일/즐겨찾기·기기 탭에서 공용)
void showAddDeviceSheet(BuildContext context) {
  final store = HomeStore.instance;
  final nameCtrl = TextEditingController();
  var type = DeviceType.light;
  var roomId = store.rooms.first.id;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기기 추가', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '기기 이름',
                filled: true,
                fillColor: context.inactiveFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('종류', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in DeviceType.values)
                ChoiceChip(
                  avatar: Icon(t.icon, size: 18),
                  label: Text(t.label),
                  selected: type == t,
                  onSelected: (_) => setState(() => type = t),
                ),
            ]),
            const SizedBox(height: 16),
            const Text('방', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final r in store.rooms)
                ChoiceChip(label: Text(r.name), selected: roomId == r.id, onSelected: (_) => setState(() => roomId = r.id)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                onPressed: () {
                  final name = nameCtrl.text.trim().isEmpty ? '새 ${type.label}' : nameCtrl.text.trim();
                  store.addDevice(name: name, type: type, roomId: roomId, actor: '홍길동');
                  Navigator.pop(context);
                },
                child: const Text('추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
