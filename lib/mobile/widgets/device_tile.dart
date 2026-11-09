import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../mobile_theme.dart';
import '../screens/device_detail_screen.dart';

/// 2열 그리드에 들어가는 기기 카드.
/// 탭하면 상세 화면, 오른쪽 위 버튼으로 바로 전원 제어.
class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device, this.showRoom = true});
  final Device device;
  final bool showRoom;

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    final d = device;
    final active = d.isActive;
    final iconBg = active ? d.type.color.withValues(alpha: 0.16) : context.inactiveFill;
    final iconFg = active ? d.type.color : context.subtle;

    return Material(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeviceDetailScreen(deviceId: d.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: Icon(d.type.icon, color: iconFg, size: 24),
                  ),
                  const Spacer(),
                  if (!d.type.isReadOnly) _PowerButton(device: d, onTap: () => store.togglePower(d)),
                ],
              ),
              const Spacer(),
              Text(
                d.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.25),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (!d.online) ...[
                    const Icon(Icons.error_outline_rounded, size: 14, color: MobileColors.offline),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      showRoom && d.online ? '${store.roomOf(d).name} · ${d.statusText}' : d.statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: !d.online ? MobileColors.offline : (active ? MobileColors.accent : context.subtle),
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.device, required this.onTap});
  final Device device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = device.isActive;
    final enabled = device.online;
    return Semantics(
      button: true,
      label: '${device.name} ${active ? '끄기' : '켜기'}',
      child: InkResponse(
        onTap: enabled ? onTap : null,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? MobileColors.accent : context.inactiveFill,
          ),
          child: Icon(
            device.type == DeviceType.doorLock
                ? (device.locked ? Icons.lock_rounded : Icons.lock_open_rounded)
                : Icons.power_settings_new_rounded,
            size: 19,
            color: active ? Colors.white : (enabled ? context.subtle : context.subtle.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

/// 그리드 레이아웃 헬퍼
class DeviceGrid extends StatelessWidget {
  const DeviceGrid({super.key, required this.devices, this.showRoom = true});
  final List<Device> devices;
  final bool showRoom;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => DeviceTile(device: devices[i], showRoom: showRoom),
          childCount: devices.length,
        ),
      ),
    );
  }
}
