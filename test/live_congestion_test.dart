import 'package:aiot/shared/restaurant.dart';
import 'package:flutter_test/flutter_test.dart';

/// 센서룸 테스터에서 ＋/− 한 인원이 서버(/api/state)를 거쳐 앱 혼잡도에 반영되는지
void main() {
  test('테스터와 같은 기준: 40%까지 여유 · 60%까지 보통 · 80%까지 혼잡 · 그 이상 매우 혼잡', () {
    expect(Congestion.fromRatio(0.4), Congestion.relaxed);
    expect(Congestion.fromRatio(24 / 60), Congestion.relaxed); // 학생식당 24명
    expect(Congestion.fromRatio(0.41), Congestion.normal);
    expect(Congestion.fromRatio(0.6), Congestion.normal);
    expect(Congestion.fromRatio(0.61), Congestion.busy);
    expect(Congestion.fromRatio(64 / 80), Congestion.busy); // 오렌지식당 64명
    expect(Congestion.fromRatio(0.81), Congestion.veryBusy);
  });

  test('서버 인원 · 수용 인원 반영 (뉴욕버거: 서버 burger → 앱 nyburger)', () {
    final st = RestaurantStore.instance;
    var notified = 0;
    void listener() => notified++;
    st.addListener(listener);
    addTearDown(() => st.removeListener(listener));

    st.applyLive('orange', 10, cap: 80);
    final o = st.byId('orange');
    expect((o.occupied, o.seats, o.congestion), (10, 80, Congestion.relaxed));

    st.applyLive('orange', 60, cap: 80); // 테스터에서 50명 추가 → 75%
    expect(o.congestion, Congestion.busy);
    expect(notified, 2);

    st.applyLive('orange', 60, cap: 80); // 같은 값이면 다시 그리지 않음
    expect(notified, 2);

    st.applyLive('nyburger', 48, cap: 40); // 정원 초과 (테스터 최대 cap + 10)
    final b = st.byId('nyburger');
    expect(b.overCapacity, isTrue);
    expect(b.ratio, 1.0);
    expect(b.congestion, Congestion.veryBusy);

    st.applyLive('faculty', 3); // cap이 없는 예전 서버 응답이면 좌석 수 유지
    expect(st.byId('faculty').seats, greaterThan(0));
  });
}
