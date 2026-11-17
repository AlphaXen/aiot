import 'package:flutter/material.dart';

import '../../shared/aiot_server.dart';
import '../../shared/restaurant.dart';
import '../../shared/study.dart';
import '../mobile_theme.dart';
import 'home_screen.dart';
import 'home_shell.dart';

const _gradeColor = {
  Grade.good: Color(0xFF16A34A),
  Grade.ok: Color(0xFFCA8A04),
  Grade.bad: Color(0xFFDC2626),
};

/// 세 번째 기능: 북카페처럼 조용히 공부할 공간 추천.
/// 식당의 빈 좌석 + 소음 · CO₂ · 온도 · 습도(센서룸 테스터 → 서버)로 쾌적도를 계산합니다.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = RestaurantStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final ranked = StudyComfort.rank(store.restaurants);
        final best = ranked.first.level == StudyLevel.poor ? null : ranked.first;
        return RefreshIndicator(
          onRefresh: AiotServer.instance.refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_library_outlined, size: 16, color: MobileColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            '스터디 스팟',
                            style: TextStyle(fontSize: 14, color: context.subtle, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '조용히 공부할 곳 찾기',
                        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BestCard(best: best, fallback: ranked.first),
              ),
              SectionTitle(
                '공간별 쾌적도',
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text('${hhmm(store.updatedAt)} 기준', style: TextStyle(fontSize: 13, color: context.subtle)),
                ),
              ),
              for (final c in ranked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: StudySpotCard(comfort: c),
                ),
              const SectionTitle('판단 기준'),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: _Criteria(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BestCard extends StatelessWidget {
  const _BestCard({required this.best, required this.fallback});
  final StudyComfort? best;
  final StudyComfort fallback;

  @override
  Widget build(BuildContext context) {
    final b = best;
    final colors = b == null
        ? const [Color(0xFF374151), Color(0xFF1F2937)]
        : const [Color(0xFF0F9F7A), Color(0xFF0E7490)];
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  b == null ? '지금은 추천할 곳이 없어요' : '지금 공부하기 가장 좋은 곳',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (b != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    b.restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${b.level.label} · ${b.score}점',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              b.summary,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in b.factors.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${f.label} ${f.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.first,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => openRestaurant(context, b.restaurant),
                icon: const Icon(Icons.place_rounded, size: 20),
                label: const Text('위치 · 상세 보기', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ] else
            Text(
              '모든 공간이 시끄럽거나 자리가 없어요.\n${fallback.restaurant.name}: ${fallback.summary}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.45),
            ),
        ],
      ),
    );
  }
}

/// 공간 하나: 점수 링 · 단계 · 요약 · 센서 칩
class StudySpotCard extends StatelessWidget {
  const StudySpotCard({super.key, required this.comfort});
  final StudyComfort comfort;

  @override
  Widget build(BuildContext context) {
    final c = comfort;
    final r = c.restaurant;
    final age = r.envAt == null ? null : DateTime.now().difference(r.envAt!);
    final stale = age != null && age.inSeconds > 60;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRestaurant(context, r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ScoreRing(score: c.score, color: c.level.color, dim: !c.hasSensors),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Pill(c.level.label, c.level.color),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          c.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: context.subtle, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final f in c.factors) _FactorChip(f)],
              ),
              if (!c.hasSensors || stale || r.envManual.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (!c.hasSensors) '센서 값 없음 · 센서룸 테스터가 켜져 있어야 해요',
                    if (stale) '센서 값 ${age.inMinutes > 0 ? '${age.inMinutes}분' : '${age.inSeconds}초'} 전',
                    if (r.envManual.isNotEmpty) '테스터에서 직접 조절한 값 포함',
                  ].join(' · '),
                  style: TextStyle(fontSize: 11.5, color: context.subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color, this.dim = false});
  final int score;
  final Color color;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: context.inactiveFill,
              color: dim ? context.subtle : color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text('$score', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _FactorChip extends StatelessWidget {
  const _FactorChip(this.f);
  final StudyFactor f;

  @override
  Widget build(BuildContext context) {
    final color = _gradeColor[f.grade]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: context.inactiveFill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(f.label, style: TextStyle(fontSize: 12, color: context.subtle)),
          const SizedBox(width: 4),
          Text(f.value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Criteria extends StatelessWidget {
  const _Criteria();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (Icons.volume_down_rounded, '소음 40%', '40 dB 이하(도서관)면 만점, 70 dB 이상 0점 · 65 dB 넘으면 비추천'),
      (Icons.event_seat_outlined, '빈 좌석 25%', '좌석 사용률 30% 이하면 만점, 90% 이상 0점'),
      (Icons.air_rounded, 'CO₂ 20%', '800 ppm 이하면 만점 · 1000 ppm 넘으면 졸리고 집중력이 떨어져요'),
      (Icons.thermostat_rounded, '온도 10% · 습도 5%', '20~24 °C, 습도 40~60 %가 가장 쾌적해요'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (icon, title, body) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: MobileColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$title  ', style: const TextStyle(fontWeight: FontWeight.w800)),
                            TextSpan(text: body, style: TextStyle(color: context.subtle)),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              '80점↑ 매우 쾌적 · 65점↑ 쾌적 · 45점↑ 보통 · 그 아래 비추천',
              style: TextStyle(fontSize: 12, color: context.subtle),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
