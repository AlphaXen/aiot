import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../mobile_theme.dart';

/// 기기 상세 제어 화면. 기기 종류에 맞는 컨트롤을 보여줍니다.
class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final d = store.byId(deviceId);
        if (d == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('삭제된 기기입니다')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name),
                Text(store.roomOf(d).name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: context.subtle)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: d.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                icon: Icon(d.favorite ? Icons.star_rounded : Icons.star_outline_rounded, color: d.favorite ? const Color(0xFFFFB300) : null),
                onPressed: () => store.toggleFavorite(d),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(device: d),
              const SizedBox(height: 12),
              ..._controlsFor(context, d),
              const SizedBox(height: 12),
              _InfoCard(device: d),
              const SizedBox(height: 12),
              _HistoryCard(device: d),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _controlsFor(BuildContext context, Device d) {
    if (!d.online) return const [];
    final store = HomeStore.instance;
    switch (d.type) {
      case DeviceType.light:
        return [
          _SliderCard(title: '밝기', icon: Icons.brightness_6_outlined, device: d, enabled: d.isOn),
        ];
      case DeviceType.tv:
        return [_SliderCard(title: '볼륨', icon: Icons.volume_up_outlined, device: d, enabled: d.isOn)];
      case DeviceType.airPurifier:
        return [_SliderCard(title: '풍량', icon: Icons.air_rounded, device: d, enabled: d.isOn)];
      case DeviceType.blind:
        return [_SliderCard(title: '열림 정도', icon: Icons.blinds_outlined, device: d, enabled: true)];
      case DeviceType.airConditioner:
        return [
          _Section(
            title: '희망 온도',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(icon: Icons.remove_rounded, onTap: d.isOn ? () => store.setTargetTemp(d, d.targetTemp - 1) : null),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${d.targetTemp}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300)),
                    const TextSpan(text: '°C', style: TextStyle(fontSize: 22)),
                  ]),
                  style: TextStyle(color: d.isOn ? null : context.subtle),
                ),
                _RoundIconButton(icon: Icons.add_rounded, onTap: d.isOn ? () => store.setTargetTemp(d, d.targetTemp + 1) : null),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '운전 모드',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const ['냉방', '제습', '송풍', '자동'])
                  _ModeChip(label: m, selected: d.mode == m, onTap: d.isOn ? () => store.setMode(d, m) : null),
              ],
            ),
          ),
        ];
      case DeviceType.robotVacuum:
        return [
          _Section(
            title: '청소 모드',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const ['일반', '강력', '조용', '물걸레'])
                  _ModeChip(label: m, selected: (d.mode.isEmpty ? '일반' : d.mode) == m, onTap: () => store.setMode(d, m)),
              ],
            ),
          ),
        ];
      case DeviceType.sensor:
        return [
          Row(
            children: [
              Expanded(child: _MetricCard(label: '온도', value: d.temperature!.toStringAsFixed(1), unit: '°C', icon: Icons.thermostat_rounded, color: const Color(0xFFFF7043))),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: '습도', value: d.humidity!.toStringAsFixed(0), unit: '%', icon: Icons.water_drop_outlined, color: const Color(0xFF3E91FF))),
            ],
          ),
        ];
      case DeviceType.camera:
        return [
          _Section(
            title: '실시간 영상',
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(d.isOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                    const SizedBox(height: 8),
                    Text(d.isOn ? '스트림 연결 대기 중' : '카메라 꺼짐', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ];
      default:
        return const [];
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.device});
  final Device device;

  @override
  Widget build(BuildContext context) {
    final d = device;
    final store = HomeStore.instance;
    final active = d.isActive;
    final canToggle = d.online && !d.type.isReadOnly;
    final label = switch (d.type) {
      DeviceType.doorLock => d.locked ? '잠김' : '열림',
      DeviceType.blind => d.level > 0 ? '열림' : '닫힘',
      DeviceType.sensor => '측정 중',
      _ => d.isOn ? '켜짐' : '꺼짐',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Semantics(
              button: canToggle,
              label: '${d.name} 전원',
              child: GestureDetector(
                onTap: canToggle ? () => store.togglePower(d) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? d.type.color : context.inactiveFill,
                    boxShadow: active ? [BoxShadow(color: d.type.color.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 10))] : null,
                  ),
                  child: Icon(
                    canToggle && d.type != DeviceType.doorLock ? Icons.power_settings_new_rounded : d.type.icon,
                    size: 52,
                    color: active ? Colors.white : context.subtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(d.online ? label : '연결 끊김',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: d.online ? null : MobileColors.offline)),
            const SizedBox(height: 4),
            Text(
              d.online ? d.statusText : '마지막 연결: ${timeAgo(d.lastSeen)}',
              style: TextStyle(color: context.subtle, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              ?trailing,
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({required this.title, required this.icon, required this.device, required this.enabled});
  final String title;
  final IconData icon;
  final Device device;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return _Section(
      title: title,
      trailing: Text('${device.level}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MobileColors.accent)),
      child: Row(
        children: [
          Icon(icon, color: context.subtle, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: device.level.toDouble(),
              min: 0,
              max: 100,
              onChanged: enabled ? (v) => store.setLevel(device, v.round()) : null,
              onChangeEnd: enabled ? (_) => store.commitLevel(device) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.inactiveFill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 52, height: 52, child: Icon(icon, color: onTap == null ? context.subtle.withValues(alpha: 0.4) : null)),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MobileColors.accent : context.inactiveFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (onTap == null ? context.subtle.withValues(alpha: 0.5) : null),
              )),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.unit, required this.icon, required this.color});
  final String label, value, unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: context.subtle)),
            ]),
            const SizedBox(height: 10),
            Text.rich(TextSpan(children: [
              TextSpan(text: value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600)),
              TextSpan(text: ' $unit', style: TextStyle(fontSize: 16, color: context.subtle)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.device});
  final Device device;

  @override
  Widget build(BuildContext context) {
    final d = device;
    final rows = <(String, String)>[
      ('기기 종류', d.type.label),
      if (d.powerWatts > 0) ('소비 전력', d.isOn && d.online ? '${d.powerWatts.toStringAsFixed(0)} W' : '대기'),
      if (d.batteryPercent != null) ('배터리', '${d.batteryPercent}%'),
      ('펌웨어', d.firmware),
    ];
    return _Section(
      title: '기기 정보',
      child: Column(
        children: [
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text(k, style: TextStyle(color: context.subtle)),
                const Spacer(),
                Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.device});
  final Device device;

  @override
  Widget build(BuildContext context) {
    final items = HomeStore.instance.logs.where((l) => l.deviceName == device.name).take(5).toList();
    return _Section(
      title: '최근 기록',
      child: items.isEmpty
          ? Text('기록이 없습니다', style: TextStyle(color: context.subtle))
          : Column(
              children: [
                for (final l in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: switch (l.level) {
                            LogLevel.error => MobileColors.offline,
                            LogLevel.warning => const Color(0xFFFFA000),
                            LogLevel.info => MobileColors.accent,
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.message)),
                      Text('${l.actor} · ${timeAgo(l.time)}', style: TextStyle(color: context.subtle, fontSize: 12.5)),
                    ]),
                  ),
              ],
            ),
    );
  }
}
