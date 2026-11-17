import 'package:flutter/material.dart';

import 'restaurant.dart';

/// 식당 환경 센서 값 (센서룸 테스터 → 서버 /api/state 의 sensors)
class EnvReading {
  const EnvReading({required this.noise, required this.co2, required this.temp, required this.hum});

  /// dB
  final double noise;

  /// ppm
  final double co2;

  /// °C
  final double temp;

  /// %
  final double hum;

  static EnvReading? fromJson(Object? j) {
    if (j is! Map) return null;
    double? d(String k) => (j[k] as num?)?.toDouble();
    final n = d('noise'), c = d('co2'), t = d('temp'), h = d('hum');
    if (n == null || c == null || t == null || h == null) return null;
    return EnvReading(noise: n, co2: c, temp: t, hum: h);
  }

  @override
  bool operator ==(Object other) =>
      other is EnvReading && other.noise == noise && other.co2 == co2 && other.temp == temp && other.hum == hum;

  @override
  int get hashCode => Object.hash(noise, co2, temp, hum);
}

/// 공부하기 좋은 정도 4단계
enum StudyLevel {
  great('매우 쾌적', Color(0xFF16A34A)),
  good('쾌적', Color(0xFF0EA5E9)),
  fair('보통', Color(0xFFCA8A04)),
  poor('비추천', Color(0xFFDC2626));

  const StudyLevel(this.label, this.color);
  final String label;
  final Color color;
}

/// 항목별 상태 (칩 색)
enum Grade { good, ok, bad }

class StudyFactor {
  const StudyFactor(this.label, this.value, this.grade, this.note);
  final String label;
  final String value;
  final Grade grade;

  /// 한 줄 설명 (추천 이유)
  final String note;
}

/// 북카페처럼 조용히 공부하기 좋은지 판단.
///
/// 점수(0~100) = 소음 40% + 빈 좌석 25% + CO₂ 20% + 온도 10% + 습도 5%
/// - 소음: 40 dB 이하(도서관) 만점 → 70 dB 이상 0점
/// - 빈 좌석: 사용률 30% 이하 만점 → 90% 이상 0점, 정원 초과 0점
/// - CO₂: 800 ppm 이하 만점 → 2000 ppm 이상 0점 (1000 넘으면 졸림 · 집중력 저하)
/// - 온도: 20~24 °C 만점, 벗어난 1 °C마다 25점 감점
/// - 습도: 40~60 % 만점, 벗어난 1 %마다 5점 감점
/// 80점↑ 매우 쾌적 · 65점↑ 쾌적 · 45점↑ 보통 · 그 아래 비추천.
/// 소음 65 dB 이상(시끄러운 식당)이거나 빈 좌석이 없으면 점수와 관계없이 비추천.
class StudyComfort {
  StudyComfort._(this.restaurant, this.score, this.level, this.factors, this.hasSensors, this.blocker);

  final Restaurant restaurant;
  final int score;
  final StudyLevel level;
  final List<StudyFactor> factors;

  /// 센서 값이 없으면 빈 좌석만으로 계산
  final bool hasSensors;

  /// 비추천 사유 (소음 · 자리 없음)
  final String? blocker;

  int get emptySeats => restaurant.overCapacity ? 0 : restaurant.seats - restaurant.occupied;

  /// 가장 좋은 점 · 가장 아쉬운 점 위주로 한 줄 요약
  String get summary {
    if (blocker != null) return blocker!;
    if (!hasSensors) return '센서 값을 기다리는 중이에요 · 빈 좌석 기준으로만 계산했어요';
    final bad = factors.where((f) => f.grade == Grade.bad).map((f) => f.note).toList();
    final good = factors.where((f) => f.grade == Grade.good).map((f) => f.note).toList();
    if (bad.isEmpty && good.isNotEmpty) return good.take(2).join(' · ');
    if (bad.isNotEmpty) return bad.take(2).join(' · ');
    return '무난하게 공부할 수 있어요';
  }

  static double _lin(double v, double best, double worst) {
    // best 이하 100, worst 이상 0 (best < worst)
    if (v <= best) return 100;
    if (v >= worst) return 0;
    return 100 * (worst - v) / (worst - best);
  }

  static double _band(double v, double lo, double hi, double perUnit) {
    if (v >= lo && v <= hi) return 100;
    final d = v < lo ? lo - v : v - hi;
    return (100 - d * perUnit).clamp(0, 100).toDouble();
  }

  static StudyComfort of(Restaurant r) {
    final env = r.env;
    final seatRatio = r.seats <= 0 ? 1.0 : r.occupied / r.seats;
    final empty = r.overCapacity ? 0 : r.seats - r.occupied;
    final seatScore = r.overCapacity ? 0.0 : _lin(seatRatio, 0.3, 0.9);

    final factors = <StudyFactor>[
      StudyFactor(
        '빈 좌석',
        '$empty석',
        seatRatio <= 0.4 ? Grade.good : (seatRatio <= 0.7 ? Grade.ok : Grade.bad),
        seatRatio <= 0.4 ? '빈 자리가 넉넉해요 ($empty석)' : (seatRatio <= 0.7 ? '빈 자리 $empty석' : '자리가 거의 없어요 ($empty석)'),
      ),
    ];

    if (env == null) {
      final score = seatScore.round();
      return StudyComfort._(
        r,
        score,
        empty == 0 ? StudyLevel.poor : _levelOf(score),
        factors,
        false,
        empty == 0 ? '빈 좌석이 없어요' : null,
      );
    }

    final noiseScore = _lin(env.noise, 40, 70);
    final co2Score = _lin(env.co2, 800, 2000);
    final tempScore = _band(env.temp, 20, 24, 25);
    final humScore = _band(env.hum, 40, 60, 5);
    final score = (0.40 * noiseScore + 0.25 * seatScore + 0.20 * co2Score + 0.10 * tempScore + 0.05 * humScore).round();

    factors.addAll([
      StudyFactor(
        '소음',
        '${env.noise.toStringAsFixed(0)} dB',
        env.noise <= 45 ? Grade.good : (env.noise <= 55 ? Grade.ok : Grade.bad),
        env.noise <= 45
            ? '도서관처럼 조용해요'
            : env.noise <= 55
            ? '대화 소리가 조금 있어요'
            : env.noise < 65
            ? '꽤 시끄러워요 · 이어폰 추천'
            : '너무 시끄러워요',
      ),
      StudyFactor(
        'CO₂',
        '${env.co2.round()} ppm',
        env.co2 <= 800 ? Grade.good : (env.co2 <= 1000 ? Grade.ok : Grade.bad),
        env.co2 <= 800 ? '공기가 상쾌해요' : (env.co2 <= 1000 ? '공기 보통' : '공기가 답답해요 · 졸릴 수 있어요'),
      ),
      StudyFactor(
        '온도',
        '${env.temp.toStringAsFixed(1)} °C',
        tempScore >= 100 ? Grade.good : (tempScore >= 50 ? Grade.ok : Grade.bad),
        tempScore >= 100 ? '온도가 딱 좋아요' : (env.temp > 24 ? '조금 더워요' : '조금 추워요'),
      ),
      StudyFactor(
        '습도',
        '${env.hum.toStringAsFixed(0)} %',
        humScore >= 100 ? Grade.good : (humScore >= 50 ? Grade.ok : Grade.bad),
        humScore >= 100 ? '습도 적당해요' : (env.hum > 60 ? '조금 습해요' : '조금 건조해요'),
      ),
    ]);

    String? blocker;
    if (empty == 0) {
      blocker = '빈 좌석이 없어요';
    } else if (env.noise >= 65) {
      blocker = '너무 시끄러워서 공부하기 어려워요 (${env.noise.toStringAsFixed(0)} dB)';
    }
    return StudyComfort._(r, score, blocker != null ? StudyLevel.poor : _levelOf(score), factors, true, blocker);
  }

  static StudyLevel _levelOf(int score) {
    if (score >= 80) return StudyLevel.great;
    if (score >= 65) return StudyLevel.good;
    if (score >= 45) return StudyLevel.fair;
    return StudyLevel.poor;
  }

  /// 공부하기 좋은 순 (비추천은 뒤로)
  static List<StudyComfort> rank(Iterable<Restaurant> list) {
    final out = list.map(of).toList()
      ..sort((a, b) {
        final pa = a.level == StudyLevel.poor ? 1 : 0, pb = b.level == StudyLevel.poor ? 1 : 0;
        if (pa != pb) return pa - pb;
        return b.score.compareTo(a.score);
      });
    return out;
  }
}
