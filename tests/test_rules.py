from crewair import nowcast
from crewair.rules import Hour, Rule, load, plan

CA = load("us-ca")


def day(pm25, temps):
    """`pm25` is the hour's NowCast in µg/m³; the AQI is derived from it, as the forecast does."""
    return [Hour(f"2026-10-24T{7 + i:02d}:00", {"pm25_nowcast_ugm3": c, "us_aqi_pm25": nowcast.aqi(c), "temp_f": t})
            for i, (c, t) in enumerate(zip(pm25, temps))]


def test_clean_day_has_no_actions():
    assert plan(day([5.0] * 4, [70] * 4), CA) == []


def test_smoke_triggers_n95_at_first_hour_over_150():
    smoke = [a for a in plan(day([30.0, 50.0, 70.0, 110.0], [70] * 4), CA) if "5141.1" in a.rule]
    assert len(smoke) == 1 and smoke[0].time.endswith("09:00") and "AQI 161" in smoke[0].text


def test_over_500_needs_respirators_not_just_n95():
    smoke = [a for a in plan(day([150.0, 600.0], [70, 70]), CA) if "5141.1" in a.rule]
    assert len(smoke) == 1 and "respirators mandatory" in smoke[0].text


def test_heat_high_beats_shade_and_clear_hours_suggested():
    acts = plan(day([5.0] * 4, [75, 82, 96, 97]), CA)
    heat = [a for a in acts if "3395" in a.rule]
    assert len(heat) == 1 and "high-heat" in heat[0].text
    assert any(a.rule == "plan" and "07:00" in a.text for a in acts)


def test_engine_is_jurisdiction_agnostic():
    rb = [Rule("x", "smoke", "pm25_ugm3", 50, "PM2.5 {value} µg/m³: masks", "Example rule")]
    acts = plan([Hour("2026-10-24T08:00", {"pm25_ugm3": 60.0})], rb)
    assert acts[0].rule == "Example rule" and "60.0" in acts[0].text


def test_nowcast_steady_level_is_that_level():
    assert nowcast.nowcast([40.0] * 12) == 40.0 and nowcast.aqi(40.0) == 112


def test_nowcast_follows_a_spike_the_daily_mean_hides():
    # 100 after eleven hours of 10: w = 0.5 → 109.9951 / 1.99951 = 55.0 µg/m³, AQI 149.
    # The plain mean of the same 12 hours is 17.5 µg/m³, AQI 67.
    assert nowcast.nowcast([100.0] + [10.0] * 11) == 55.0 and nowcast.aqi(55.0) == 149


def test_nowcast_needs_two_of_the_last_three_hours():
    assert nowcast.nowcast([30.0, None, None, 30.0]) is None
    assert nowcast.nowcast([30.0]) is None
