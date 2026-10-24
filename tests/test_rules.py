from crewair.rules import Hour, Rule, load, plan

CA = load("us-ca")


def day(aqi, temps):
    return [Hour(f"2026-10-24T{7 + i:02d}:00", {"us_aqi_pm25": a, "temp_f": t})
            for i, (a, t) in enumerate(zip(aqi, temps))]


def test_clean_day_has_no_actions():
    assert plan(day([30] * 4, [70] * 4), CA) == []


def test_smoke_triggers_n95_at_first_hour_over_150():
    smoke = [a for a in plan(day([90, 140, 160, 180], [70] * 4), CA) if "5141.1" in a.rule]
    assert len(smoke) == 1 and smoke[0].time.endswith("09:00") and "N95" in smoke[0].text


def test_over_500_needs_respirators_not_just_n95():
    smoke = [a for a in plan(day([200, 520], [70, 70]), CA) if "5141.1" in a.rule]
    assert len(smoke) == 1 and "respirators mandatory" in smoke[0].text


def test_heat_high_beats_shade_and_clear_hours_suggested():
    acts = plan(day([20] * 4, [75, 82, 96, 97]), CA)
    heat = [a for a in acts if "3395" in a.rule]
    assert len(heat) == 1 and "high-heat" in heat[0].text
    assert any(a.rule == "plan" and "07:00" in a.text for a in acts)


def test_engine_is_jurisdiction_agnostic():
    rb = [Rule("x", "smoke", "pm25_ugm3", 50, "PM2.5 {value} µg/m³: masks", "Example rule")]
    acts = plan([Hour("2026-10-24T08:00", {"pm25_ugm3": 60.0})], rb)
    assert acts[0].rule == "Example rule" and "60.0" in acts[0].text
