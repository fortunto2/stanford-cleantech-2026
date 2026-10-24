from crewair.rules import Hour, plan


def day(aqi, temps):
    return [Hour(f"2026-10-24T{7 + i:02d}:00", a, t) for i, (a, t) in enumerate(zip(aqi, temps))]


def test_clean_day_has_no_actions():
    assert plan(day([30] * 4, [70] * 4)) == []


def test_smoke_triggers_n95_at_first_hour_over_150():
    acts = plan(day([90, 140, 160, 180], [70] * 4))
    smoke = [a for a in acts if a.rule == "§5141.1"]
    assert len(smoke) == 1 and smoke[0].time.endswith("09:00") and "N95" in smoke[0].text


def test_over_500_needs_respirators_not_just_n95():
    acts = plan(day([200, 520], [70, 70]))
    assert [a.text.split(":")[1].strip().split(",")[0] for a in acts if a.rule == "§5141.1"] == ["respirators mandatory"]


def test_heat_high_beats_shade_and_clear_hours_suggested():
    acts = plan(day([20, 20, 20, 20], [75, 82, 96, 97]))
    heat = [a for a in acts if a.rule == "§3395"]
    assert len(heat) == 1 and "high-heat" in heat[0].text
    assert any(a.rule == "plan" and "07:00" in a.text for a in acts)
