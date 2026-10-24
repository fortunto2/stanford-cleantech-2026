// Crew Air demo-day model: a pure module, no DOM. Everything the figure shows comes from here.
// PM2.5 hourly means for one demo day (µg/m³), 00:00 … 17:00. The shift is 07:00 … 17:00.
export const SHIFT = [7, 17];
export const PM25 = [7, 7, 7, 7, 8, 8, 8, 8, 9, 12, 20, 38, 60, 75, 68, 52, 40, 30];
export const TEMP_F = [58, 84]; // at 07:00 and 17:00, rising linearly
export const WIND = { from: "NW", kmh: 6, dir: [1, 1] }; // blows toward SE: +x, +y in the bench's frame

export const N95_AQI = 151; // Cal/OSHA §5141.1: AQI (PM2.5) 151+ → N95s provided
export const SHADE_F = 80; // Cal/OSHA §3395: shade up at 80 °F
export const HIGH_HEAT_F = 95; // §3395 high-heat procedures

// 2024 EPA PM2.5 breakpoints: [c_lo, c_hi, aqi_lo, aqi_hi]
export const BREAKPOINTS = [
  [0, 9.0, 0, 50],
  [9.1, 35.4, 51, 100],
  [35.5, 55.4, 101, 150],
  [55.5, 125.4, 151, 200],
  [125.5, 225.4, 201, 300],
  [225.5, 325.4, 301, 500],
];

export function aqiOf(c) {
  const x = Math.round(c * 10) / 10;
  for (const [cl, ch, al, ah] of BREAKPOINTS) if (x >= cl && x <= ch) return Math.round(al + ((x - cl) * (ah - al)) / (ch - cl));
  if (x < 0) return 0;
  if (x > 325.4) return 500;
  // between truncated breakpoints (e.g. 9.05): take the lower band's top
  for (let i = 0; i < BREAKPOINTS.length - 1; i++) if (x > BREAKPOINTS[i][1] && x < BREAKPOINTS[i + 1][0]) return BREAKPOINTS[i][3];
  return 0;
}

// EPA NowCast for PM: the 12 hours ending at `hour` (integer), w = clamp(min/max, 0.5, 1).
export function nowcast(series, hour) {
  const window = [];
  for (let i = 0; i < 12; i++) {
    const h = hour - i;
    if (h < 0) break;
    window.push(series[h]);
  }
  const lo = Math.min(...window), hi = Math.max(...window);
  const w = Math.max(0.5, Math.min(1, hi > 0 ? lo / hi : 1));
  let num = 0, den = 0;
  window.forEach((c, i) => { num += Math.pow(w, i) * c; den += Math.pow(w, i); });
  return num / den;
}

export const tempAt = (h) => TEMP_F[0] + ((TEMP_F[1] - TEMP_F[0]) * (h - SHIFT[0])) / (SHIFT[1] - SHIFT[0]);

const lerp = (a, b, t) => a + (b - a) * t;

// State at a fractional hour of the shift: concentrations, NowCast and AQI interpolated between hours.
export function stateAt(hour) {
  const h = Math.max(SHIFT[0], Math.min(SHIFT[1], hour));
  const h0 = Math.floor(h), h1 = Math.min(SHIFT[1], h0 + 1), t = h - h0;
  const nc = lerp(nowcast(PM25, h0), nowcast(PM25, h1), t);
  const pm = lerp(PM25[h0], PM25[h1], t);
  const aqi = aqiOf(nc);
  const temp = tempAt(h);
  const rules = [];
  if (aqi >= N95_AQI) rules.push("N95s available, §5141.1");
  if (temp >= SHADE_F) rules.push("shade and water, §3395");
  return { hour: h, pm, nowcast: nc, aqi, temp, rules, rule: rules.length ? rules.join(" · ") : "none" };
}

export const hourLabel = (h) => {
  const hh = Math.floor(h), mm = Math.round((h - hh) * 60);
  return `${String(hh).padStart(2, "0")}:${String(mm === 60 ? 0 : mm).padStart(2, "0")}`;
};

// The first hour of the shift at which each rule starts (null if never).
export function startsOf() {
  let n95 = null, heat = null;
  for (let h = SHIFT[0]; h <= SHIFT[1]; h += 1 / 60) {
    const s = stateAt(h);
    if (n95 === null && s.aqi >= N95_AQI) n95 = h;
    if (heat === null && s.temp >= SHADE_F) heat = h;
  }
  return { n95, heat };
}
