import 'package:flutter/material.dart';

import '../../shared/home_store.dart';
import '../../shared/models.dart';
import '../mobile_theme.dart';
import 'home_shell.dart';

/// 라이프: 에너지 · 공기질 · 보안 요약 카드
class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HomeStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final energy = store.weeklyEnergy;
        final maxE = energy.reduce((a, b) => a > b ? a : b);
        final lock = store.devices.where((d) => d.type == DeviceType.doorLock).firstOrNull;
        final purifier = store.devices.where((d) => d.type == DeviceType.airPurifier).firstOrNull;
        const days = ['월', '화', '수', '목', '금', '토', '오늘'];
        return CustomScrollView(
          slivers: [
            const LargeHeader(title: '라이프', showLocation: true),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(children: [
                _LifeCard(
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFFFFB300),
                  title: '에너지',
                  subtitle: '이번 주 ${energy.fold(0.0, (a, b) => a + b).toStringAsFixed(1)}kWh 사용',
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < energy.length; i++)
                          Expanded(
                            child: Tooltip(
                              message: '${days[i]} ${energy[i].toStringAsFixed(1)}kWh',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 90 * energy[i] / maxE,
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: i == energy.length - 1 ? MobileColors.accent : MobileColors.accent.withValues(alpha: 0.3),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(days[i], style: TextStyle(fontSize: 11.5, color: context.subtle)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LifeCard(
                  icon: Icons.air_rounded,
                  color: const Color(0xFF00B8A9),
                  title: '공기',
                  subtitle: purifier == null ? '공기청정기 없음' : '${purifier.name} ${purifier.isOn ? '작동 중' : '꺼짐'}',
                  child: Row(children: [
                    const _AirBadge(label: '미세먼지', value: '좋음', ok: true),
                    const SizedBox(width: 10),
                    const _AirBadge(label: '초미세먼지', value: '보통', ok: true),
                    const SizedBox(width: 10),
                    _AirBadge(
                      label: '습도',
                      value: '${store.devices.where((d) => d.type == DeviceType.sensor).first.humidity!.toStringAsFixed(0)}%',
                      ok: true,
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                _LifeCard(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF7E57C2),
                  title: '보안',
                  subtitle: lock == null ? '도어락 없음' : '현관 ${lock.locked ? '잠김' : '열림'}',
                  child: lock == null
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.tonalIcon(
                            onPressed: () => store.togglePower(lock),
                            icon: Icon(lock.locked ? Icons.lock_open_rounded : Icons.lock_rounded),
                            label: Text(lock.locked ? '잠금 해제' : '지금 잠그기'),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _LifeCard extends StatelessWidget {
  const _LifeCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.child});
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: context.subtle, fontSize: 13)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: context.subtle),
            ]),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _AirBadge extends StatelessWidget {
  const _AirBadge({required this.label, required this.value, required this.ok});
  final String label, value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: context.inactiveFill, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.subtle)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF1E8E4E) : MobileColors.offline)),
        ]),
      ),
    );
  }
}
