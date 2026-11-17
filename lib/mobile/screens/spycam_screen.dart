import 'package:flutter/material.dart';

import '../../shared/restaurant.dart';
import '../mobile_theme.dart';
import '../services/spycam_service.dart';
import 'home_shell.dart';
import 'spycam_scan_screen.dart';

const _danger = Color(0xFFEF4444);
const _safe = Color(0xFF22C55E);

void openSpycamScan(BuildContext context, {String? roomId}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpycamScanScreen(roomId: roomId)));

/// 두 번째 기능: 몰래카메라 찾기.
/// 센서룸 SDR이 몰카 신호를 잡으면(서버 camera != null) 여기에 경보가 뜨고,
/// 카메라로 몰카를 찍어 인식되면 수거 → 귀신 검거.
class SpycamScreen extends StatelessWidget {
  const SpycamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = SpycamService.instance;
    return ListenableBuilder(
      listenable: svc,
      builder: (context, _) {
        final planted = svc.planted;
        return RefreshIndicator(
          onRefresh: svc.refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: MobileColors.accent),
                                const SizedBox(width: 3),
                                Text(
                                  '안심 캠퍼스',
                                  style: TextStyle(fontSize: 14, color: context.subtle, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '몰래카메라 찾기',
                              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                            ),
                          ],
                        ),
                      ),
                      _ConnBadge(conn: svc.conn),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AlertCard(planted: planted),
              ),
              SectionTitle(
                '식당별 RF 감시',
                trailing: svc.syncedAt == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          '${hhmm(svc.syncedAt!)} 기준',
                          style: TextStyle(fontSize: 13, color: context.subtle),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [for (final r in svc.rooms) _RoomTile(room: r)],
                  ),
                ),
              ),
              const SectionTitle('찾는 방법'),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: _HowTo(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnBadge extends StatelessWidget {
  const _ConnBadge({required this.conn});
  final SpyConn conn;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (conn) {
      SpyConn.online => ('실시간 연결', _safe),
      SpyConn.connecting => ('연결 중', const Color(0xFFF59E0B)),
      SpyConn.error => ('연결 끊김', _danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.planted});
  final List<SpyRoom> planted;

  @override
  Widget build(BuildContext context) {
    final alarm = planted.isNotEmpty;
    final colors = alarm ? const [Color(0xFFEF4444), Color(0xFFB91C1C)] : const [Color(0xFF1F2937), Color(0xFF374151)];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alarm ? Icons.warning_amber_rounded : Icons.verified_user_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                alarm ? '몰카 신호 감지 ${planted.length}곳' : '감지된 몰카 없음',
                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alarm ? '${planted.map((r) => r.name).join(', ')}에\n몰래카메라가 숨어 있어요' : '지금은 모든 식당이 안전해요',
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            alarm
                ? '책상 밑의 빨간 불빛을 카메라로 찍으면\n몰카를 수거하고 귀신을 잡을 수 있어요'
                : '센서룸에서 귀신이 몰카를 설치하면 바로 알려 드려요',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.first,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => openSpycamScan(context, roomId: alarm ? planted.first.id : null),
              icon: const Icon(Icons.photo_camera_rounded, size: 20),
              label: Text(
                alarm ? '카메라로 몰카 잡기' : '카메라 탐지 연습하기',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});
  final SpyRoom room;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.restaurant_rounded;
    for (final r in RestaurantStore.instance.restaurants) {
      if (r.id == room.restaurantId) icon = r.icon;
    }
    final on = room.planted;
    return ListTile(
      onTap: on ? () => openSpycamScan(context, roomId: room.id) : null,
      leading: CircleAvatar(
        backgroundColor: (on ? _danger : context.inactiveFill).withValues(alpha: on ? 0.14 : 1),
        child: Icon(icon, color: on ? _danger : context.subtle, size: 22),
      ),
      title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        on ? '지속 RF 신호 ${room.freqMhz?.toStringAsFixed(1) ?? '-'} MHz · 몰카 의심' : '2.4 GHz 대역 정상',
        style: TextStyle(color: on ? _danger : context.subtle, fontSize: 13),
      ),
      trailing: on
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('잡으러 가기', style: TextStyle(color: _danger, fontWeight: FontWeight.w700, fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: _danger),
              ],
            )
          : const Icon(Icons.check_circle_rounded, color: _safe),
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.sensors_rounded, '식당의 SDR 센서가 2.4 GHz 대역에서 끊기지 않는 무선 신호를 찾아 몰카를 의심해요'),
      (Icons.center_focus_strong_rounded, '카메라 조준선 안에 책상 밑의 빨간 LED와 검은 카메라 몸체를 담아요'),
      (Icons.photo_camera_rounded, '촬영 버튼을 누르면 AI가 불빛을 분석해 몰카인지 판정해요'),
      (Icons.sentiment_very_satisfied_rounded, '인식되면 몰카가 수거되고 센서룸 화면에서 귀신이 잡혀요'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          children: [
            for (final (i, (icon, text)) in steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: MobileColors.accent.withValues(alpha: 0.14),
                      child: Icon(icon, size: 17, color: MobileColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text('${i + 1}. $text', style: const TextStyle(height: 1.45)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
