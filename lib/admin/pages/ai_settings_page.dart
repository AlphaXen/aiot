import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/restaurant.dart';
import '../admin_store.dart';
import '../admin_theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class AiSettingsPage extends StatelessWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final st = RestaurantStore.instance;
    final a = AdminStore.instance;
    const from = RestaurantStore.campusCenter;
    final fixed = st.fixedRecommendId;
    final ranking = st.ranking(from);
    final pick = st.recommend(from);

    void setFixed(String? id) {
      st.updateAiSettings(fixedId: id);
      a.log(AdminLog(LogLevel.info, 'AI 추천', id == null ? '자동 추천 모드로 변경' : '추천 고정: ${st.byId(id).name}', actor: AdminStore.adminName));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'AI 추천 설정', description: '사용자 앱 "내 위치로 추천받기"에서 어떤 식당을 추천할지 정합니다'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AdminTokens.ai.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTokens.ai.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AdminTokens.ai, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '개발 단계: 서버 연동 전이라 여기서 바꾼 설정은 이 화면의 미리보기에만 적용됩니다. 배포된 사용자 앱은 오렌지식당 고정으로 동작합니다.',
                  style: TextStyle(fontSize: 13, color: t.textSub),
                ),
              ),
            ],
          ),
        ),
        TwoCol(
          leftFlex: 1,
          rightFlex: 1,
          left: Column(
            children: [
              Panel(
                title: '추천 모드',
                child: RadioGroup<bool>(
                  groupValue: fixed != null,
                  onChanged: (v) => setFixed(v == true ? 'orange' : null),
                  child: Column(
                    children: [
                      _ModeTile(
                        value: true,
                        title: '고정 추천 (개발용)',
                        subtitle: '위치 · 혼잡도와 관계없이 항상 같은 식당을 추천합니다',
                        trailing: fixed == null
                            ? null
                            : FilterDropdown<String>(
                                label: '식당',
                                value: fixed,
                                items: {for (final r in st.restaurants) r.id: r.name},
                                onChanged: setFixed,
                              ),
                      ),
                      const SizedBox(height: 8),
                      const _ModeTile(value: false, title: '자동 추천', subtitle: '영업 중인 식당 중 혼잡도와 거리 점수가 가장 좋은 곳을 추천합니다'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Panel(
                title: '점수 가중치',
                subtitle: '자동 추천에 사용 · 점수 = 혼잡도 × 비중 + 거리 × (1 − 비중), 낮을수록 추천',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('거리 우선', style: TextStyle(fontSize: 13, color: t.textMuted)),
                        Expanded(
                          child: Slider(
                            value: st.congestionWeight,
                            divisions: 10,
                            label: '혼잡도 ${(st.congestionWeight * 100).round()}%',
                            onChanged: (v) => st.updateAiSettings(weight: v),
                          ),
                        ),
                        Text('혼잡도 우선', style: TextStyle(fontSize: 13, color: t.textMuted)),
                      ],
                    ),
                    Text(
                      '혼잡도 ${(st.congestionWeight * 100).round()}% · 거리 ${((1 - st.congestionWeight) * 100).round()}%',
                      style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                    ),
                    const SizedBox(height: 18),
                    Text('최대 고려 거리', style: TextStyle(fontSize: 13, color: t.textMuted)),
                    Slider(
                      value: st.maxDistanceMeters,
                      min: 200,
                      max: 2000,
                      divisions: 18,
                      label: '${st.maxDistanceMeters.round()}m',
                      onChanged: (v) => st.updateAiSettings(maxDistance: v),
                    ),
                    Text(
                      '${st.maxDistanceMeters.round()}m 이상은 거리 점수 최하 (도보 약 ${(st.maxDistanceMeters / 67).ceil()}분)',
                      style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          right: Panel(
            title: '추천 미리보기',
            subtitle: '기준 위치: 캠퍼스 중심 · 지금 혼잡도 기준',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6D5BFF), Color(0xFF3E91FF)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      RestaurantAvatar(restaurant: pick, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fixed != null ? 'AI 추천 (고정)' : 'AI 추천 (자동)',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              pick.name,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HScroll(
                  minWidth: 520,
                  child: AdminTable(
                    columns: const ['순위', '식당', '혼잡도', '거리', '점수'],
                    flex: const [7, 22, 16, 11, 10],
                    rows: [
                      for (var i = 0; i < ranking.length; i++)
                        [
                          Text(
                            ranking[i].$2 == null ? '-' : '${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: t.text),
                          ),
                          Row(
                            children: [
                              RestaurantAvatar(restaurant: ranking[i].$1, size: 30),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  ranking[i].$1.name,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                                ),
                              ),
                            ],
                          ),
                          CongestionBadge(ranking[i].$1.congestion),
                          Text(
                            '${const Distance().as(LengthUnit.Meter, from, ranking[i].$1.position).round()}m',
                            style: TextStyle(color: t.textSub, fontSize: 13),
                          ),
                          Text(
                            ranking[i].$2?.toStringAsFixed(2) ?? '영업 종료',
                            style: TextStyle(
                              color: ranking[i].$2 == null ? t.textMuted : t.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '최근 7일 추천 요청',
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                ),
                const SizedBox(height: 10),
                BarChart(values: a.weeklyAiRequests, labels: last7DayLabels(), unit: '회', height: 170),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.value, required this.title, required this.subtitle, this.trailing});
  final bool value;
  final String title, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = AdminTokens.of(context);
    final selected = RadioGroup.maybeOf<bool>(context)?.groupValue == value;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AdminTokens.accent : t.border, width: selected ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Radio<bool>(value: value),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                ),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: t.textMuted)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
