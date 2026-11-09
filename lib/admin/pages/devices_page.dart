import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../admin_theme.dart';
import '../widgets/common.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  String _query = '';
  String _room = 'all';
  String _type = 'all';
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final s = HomeStore.instance;
    final list = s.devices.where((d) {
      if (_query.isNotEmpty && !d.name.toLowerCase().contains(_query.toLowerCase())) return false;
      if (_room != 'all' && d.roomId != _room) return false;
      if (_type != 'all' && d.type.name != _type) return false;
      if (_status == 'online' && !d.online) return false;
      if (_status == 'offline' && d.online) return false;
      return true;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: '기기',
        description: '등록된 기기 ${s.devices.length}대 · 온라인 ${s.onlineCount}대',
        actions: [FilledButton.icon(onPressed: () => _addDialog(context), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('기기 추가'))],
      ),
      // 필터는 차트/표 위 한 줄
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: '기기 이름 검색', prefixIcon: Icon(Icons.search_rounded, size: 20)),
          ),
        ),
        FilterDropdown<String>(
          label: '방',
          value: _room,
          items: {'all': '모든 방', for (final r in s.rooms) r.id: r.name},
          onChanged: (v) => setState(() => _room = v),
        ),
        FilterDropdown<String>(
          label: '종류',
          value: _type,
          items: {'all': '모든 종류', for (final ty in DeviceType.values) ty.name: ty.label},
          onChanged: (v) => setState(() => _type = v),
        ),
        FilterDropdown<String>(
          label: '상태',
          value: _status,
          items: const {'all': '모든 상태', 'online': '온라인', 'offline': '오프라인'},
          onChanged: (v) => setState(() => _status = v),
        ),
        Text('${list.length}개 표시', style: TextStyle(color: t.textMuted, fontSize: 13)),
      ]),
      const SizedBox(height: 16),
      Panel(
        padding: EdgeInsets.zero,
        child: _HScroll(
          minWidth: 980,
          child: AdminTable(
            columns: const ['기기', '방', '연결', '현재 상태', '펌웨어', '마지막 연결', '제어'],
            flex: const [26, 10, 11, 16, 9, 11, 12],
            emptyText: '조건에 맞는 기기가 없습니다',
            onRowTap: (i) => showDeviceDialog(context, list[i]),
            rows: [
              for (final d in list)
                [
                  Row(children: [
                    DeviceAvatar(type: d.type),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.name, style: TextStyle(fontWeight: FontWeight.w700, color: t.text), overflow: TextOverflow.ellipsis),
                        Text('${d.type.label} · ${d.id}', style: TextStyle(fontSize: 12, color: t.textMuted)),
                      ]),
                    ),
                  ]),
                  Text(s.roomOf(d).name, style: TextStyle(color: t.textSub)),
                  StatusBadge.online(d.online),
                  Text(d.online ? d.statusText : '-', style: TextStyle(color: t.textSub)),
                  Text(d.firmware, style: TextStyle(color: d.firmware == HomeStore.latestFirmware ? t.textSub : AdminTokens.warning, fontWeight: FontWeight.w600)),
                  Text(d.online ? '실시간' : timeAgo(d.lastSeen), style: TextStyle(color: t.textMuted, fontSize: 13)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (!d.type.isReadOnly)
                      Switch(
                        value: d.isActive,
                        onChanged: d.online ? (_) => s.togglePower(d, actor: '관리자') : null,
                      ),
                    if (!d.online)
                      TextButton(onPressed: () => s.reconnect(d), child: const Text('재연결')),
                  ]),
                ],
            ],
          ),
        ),
      ),
    ]);
  }

  void _addDialog(BuildContext context) {
    final s = HomeStore.instance;
    final name = TextEditingController();
    var type = DeviceType.light;
    var room = s.rooms.first.id;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('기기 추가'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: '기기 이름')),
              const SizedBox(height: 14),
              DropdownButtonFormField<DeviceType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: '종류'),
                items: [for (final ty in DeviceType.values) DropdownMenuItem(value: ty, child: Text(ty.label))],
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: room,
                decoration: const InputDecoration(labelText: '방'),
                items: [for (final r in s.rooms) DropdownMenuItem(value: r.id, child: Text(r.name))],
                onChanged: (v) => setState(() => room = v ?? room),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            FilledButton(
              onPressed: () {
                s.addDevice(name: name.text.trim().isEmpty ? '새 ${type.label}' : name.text.trim(), type: type, roomId: room);
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기기 상세/편집 다이얼로그 (이름 변경, 방 이동, 삭제)
void showDeviceDialog(BuildContext context, Device d) {
  final s = HomeStore.instance;
  final t = AdminTokens.of(context);
  final name = TextEditingController(text: d.name);
  var room = d.roomId;
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Row(children: [
          DeviceAvatar(type: d.type, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${d.type.label} · ${d.id}', style: TextStyle(fontSize: 12.5, color: t.textMuted)),
            ]),
          ),
          StatusBadge.online(d.online),
        ]),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            _kv(t, '현재 상태', d.online ? d.statusText : '연결 끊김'),
            _kv(t, '펌웨어', d.firmware == HomeStore.latestFirmware ? '${d.firmware} (최신)' : '${d.firmware} → ${HomeStore.latestFirmware} 가능'),
            if (d.batteryPercent != null) _kv(t, '배터리', '${d.batteryPercent}%'),
            if (d.powerWatts > 0) _kv(t, '정격 전력', '${d.powerWatts.toStringAsFixed(0)} W'),
            _kv(t, '마지막 연결', d.online ? '실시간' : ymdhm(d.lastSeen)),
            const SizedBox(height: 18),
            TextField(controller: name, decoration: const InputDecoration(labelText: '이름')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: room,
              decoration: const InputDecoration(labelText: '방'),
              items: [for (final r in s.rooms) DropdownMenuItem(value: r.id, child: Text(r.name))],
              onChanged: (v) => setState(() => room = v ?? room),
            ),
          ]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AdminTokens.critical),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('기기를 삭제할까요?'),
                  content: Text('"${d.name}"을(를) 삭제하면 관련 자동화가 동작하지 않을 수 있습니다.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: AdminTokens.critical), onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                s.removeDevice(d);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('삭제'),
          ),
          const SizedBox(width: 40),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          FilledButton(
            onPressed: () {
              if (name.text.trim() != d.name) s.renameDevice(d, name.text);
              if (room != d.roomId) s.moveDevice(d, room);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

Widget _kv(AdminTokens t, String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 110, child: Text(k, style: TextStyle(color: t.textMuted, fontSize: 13.5))),
        Expanded(child: Text(v, style: TextStyle(color: t.text, fontWeight: FontWeight.w600, fontSize: 13.5))),
      ]),
    );

/// 좁은 화면에서 표가 찌그러지지 않도록 가로 스크롤
class _HScroll extends StatelessWidget {
  const _HScroll({required this.child, required this.minWidth});
  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= minWidth) return child;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: minWidth, child: child));
    });
  }
}
