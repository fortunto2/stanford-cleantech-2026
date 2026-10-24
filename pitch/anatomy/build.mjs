// Crew Air · Fig 1 · The hour the rule starts. Builds crew-air.html (dark) or crew-air-light.html (--light).
import { writeFileSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import * as k from "/Users/rustam/.claude/skills/anatomy/kit/iso-kit.mjs";
import { kitScript } from "/Users/rustam/.claude/skills/anatomy/scripts/inline-kit.mjs";
import * as M from "./model.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const theme = process.argv.includes("--light") ? "light" : "dark";

const WIDTH = 640;
const HEIGHT = 420;

// --- world (units ≈ px of the real bench), x right-front, y left-front, z up ---
const PLATE = { x: -150, y: -75, w: 300, d: 150, r: 8 };
const PLATE_H = 12;
const FOOT_H = 5;

const HOUR_X = (h) => -100 + (h - M.SHIFT[0]) * 20; // 07:00 → -100, 17:00 → +100
const RAIL = { x: -112, y: 19, w: 224, d: 6, r: 1 };
const RAIL_H = 4;
const CAR = { x: -14, y: 10, w: 28, d: 26, r: 2 };
const CAR_Z = 6;
const CAR_TOP = 13;
const BUSH = { x: -12, y: 16, w: 24, d: 12, r: 1 };
const STRIP = { x: -112, y: 46, w: 224, d: 8, r: 1 };

const DIAL = [-20, -30];
const DIAL_R = 24;
const DIAL_Z = 58;
const DIAL_H = 10;
const DIAL_TOP = DIAL_Z + DIAL_H;
const SCALE_FROM = (-135 * Math.PI) / 180;
const SCALE_SPAN = (270 * Math.PI) / 180;
const AQI_MAX = 300;

const THERM = { x: 24, y: -48, w: 12, d: 4, r: 0 }; // back plate
const TUBE = [34, -41.5];
const TUBE_R = 1.6;
const T_Z0 = 6, T_Z1 = 54; // 50 °F … 100 °F
const zOfF = (f) => T_Z0 + ((f - 50) / 50) * (T_Z1 - T_Z0);

const STACK = [-110, -62];
const STACK_BLOCK = { x: -120, y: -70, w: 20, d: 16, r: 1.5 };
const STACK_TOP = 34;
const WIND_DIR = (() => { const v = [134, 84]; const n = Math.hypot(...v); return [v[0] / n, v[1] / n]; })();
const VANE = [-128, -38];
const VANE_Z = 28;

const LABEL = { x: 70, y: -66, w: 52, d: 22, r: 1.5 };
const SLOT = { x: 60, y: PLATE.y + PLATE.d - 0.4, w: 40, d: 0.8, r: 0.3 };
const PAPER_X = 62, PAPER_W = 36, PAPER_Z = -6, PAPER_OUT = 26;

const P = k.fitProjection(
  [
    ...k.boxCorners(PLATE, -PLATE_H - FOOT_H, 0),
    [DIAL[0] - DIAL_R, DIAL[1] - DIAL_R, DIAL_TOP],
    [DIAL[0] + DIAL_R, DIAL[1] + DIAL_R, DIAL_TOP],
    [STACK[0], STACK[1], STACK_TOP + 2],
    [PAPER_X, PLATE.y + PLATE.d + PAPER_OUT, PAPER_Z],
  ],
  WIDTH,
  HEIGHT,
  { pad: 26, azimuth: 42 },
);

const at = (point) => k.iso(point, P);
const S = (paths, style) => k.solidSvg(paths, style);
const L = (d, style) => k.lineSvg(d, style);
const D = (points, style) => k.dotsSvg(points, style);
const byDepth = (points) => [...points].sort((a, b) => k.depthOf([a[0], a[1], 0], P) - k.depthOf([b[0], b[1], 0], P));

// --- static parts ---
function plate() {
  const out = [`<path class="iso-halo" d="${k.haloOf(PLATE, -PLATE_H - FOOT_H, PLATE_H, P)}"/>`];
  for (const [x, y] of byDepth(k.corners(PLATE, 22))) {
    out.push(S(k.cylinder(x, y, 7, -PLATE_H - FOOT_H, 1.6, P, 28), { tone: "lo" }));
    out.push(S(k.cylinder(x, y, 5.4, -PLATE_H - FOOT_H + 1.6, FOOT_H - 1.6, P, 28), { tone: "mid" }));
  }
  out.push(S(k.slabOf(PLATE, -PLATE_H, PLATE_H, P, 8, 1.6), { tone: "mid" }));
  out.push(L(k.planOutline(k.insetPlan(PLATE, 5), 0, P), { tone: "lo" }));
  const screws = k.corners(PLATE, 10);
  out.push(L(screws.map(([x, y]) => k.ring(x, y, 2.2, 0, P, 16)).join(""), { tone: "lo" }));
  out.push(D(screws.map(([x, y]) => at([x, y, 0])), { size: 0.5 }));
  // ruler strip: the shift hours, a tick every hour, majors at 07, 12 and 17
  out.push(S(k.slabOf(STRIP, 0, 0.6, P, 3), { tone: "lo", crease: "none" }));
  const ticks = k.topTicks(HOUR_X(7), HOUR_X(17), 20, 5, STRIP.y + 0.6, 0.6, [2.4, 4.2], P);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  const half = k.topTicks(HOUR_X(7) + 10, HOUR_X(17) - 10, 20, 1, STRIP.y + 0.6, 0.6, [1.2, 1.2], P);
  out.push(L(half.minor + half.major, { tone: "faint" }));
  out.push(D([at([STRIP.x + 3, STRIP.y + 6, 0.6]), at([STRIP.x + STRIP.w - 3, STRIP.y + 6, 0.6])], { size: 0.45 }));
  out.push(k.faceTextSvg(k.topMatrix([HOUR_X(7) - 1.5, STRIP.y + 6.3], 0.6, P, "x"), "07", { size: 2.2, tone: "lo", anchor: "middle" }));
  out.push(k.faceTextSvg(k.topMatrix([HOUR_X(17) + 1.5, STRIP.y + 6.3], 0.6, P, "x"), "17", { size: 2.2, tone: "lo", anchor: "middle" }));
  // label plate with three rule lines
  out.push(S(k.slabOf(LABEL, 0, 0.8, P, 4), { tone: "mid" }));
  out.push(L(k.planOutline(k.insetPlan(LABEL, 1.6), 0.8, P), { tone: "faint" }));
  [[6, 38], [10, 30], [14, 42]].forEach(([dy, len]) => out.push(L(k.lineOnTop([LABEL.x + 5, LABEL.y + dy], [LABEL.x + 5 + len, LABEL.y + dy], 0.8, P), { tone: "lo", free: true })));
  out.push(D([at([LABEL.x + 2.4, LABEL.y + LABEL.d / 2, 0.8]), at([LABEL.x + LABEL.w - 2.4, LABEL.y + LABEL.d / 2, 0.8])], { size: 0.45 }));
  // ticket slot on the front face
  out.push(S(k.slabOf(SLOT, -8.5, 5.5, P, 2), { tone: "lo", crease: "none" }));
  out.push(L(k.segment([SLOT.x + 2, SLOT.y + SLOT.d, -5.7], [SLOT.x + SLOT.w - 2, SLOT.y + SLOT.d, -5.7], P), { tone: "faint" }));
  return out.join("");
}

function smokeSide() {
  const out = [];
  out.push(S(k.slabOf(STACK_BLOCK, 0, 10, P, 4, 0.8), { tone: "mid" }));
  out.push(L(k.planOutline(k.insetPlan(STACK_BLOCK, 2.5), 10, P, 4), { tone: "faint" }));
  out.push(D(k.corners(STACK_BLOCK, 2.5).map(([x, y]) => at([x, y, 10])), { size: 0.4, tone: "lo" }));
  out.push(S(k.cylinder(STACK[0], STACK[1], 4.6, 10, 2, P, 28), { tone: "mid" }));
  out.push(S(k.cylinder(STACK[0], STACK[1], 3.2, 12, STACK_TOP - 12, P, 28), { tone: "mid", crease: "none" }));
  out.push(L([18, 24].map((z) => k.sideArc(STACK[0], STACK[1], 3.2, z, P, 16)).join(""), { tone: "faint" }));
  out.push(S(k.cylinder(STACK[0], STACK[1], 3.8, STACK_TOP - 4, 1.4, P, 28), { tone: "mid" }));
  out.push(S(k.cylinder(STACK[0], STACK[1], 4, STACK_TOP, 1.6, P, 28), { tone: "hi" }));
  out.push(L(k.ring(STACK[0], STACK[1], 2.6, STACK_TOP + 1.6, P, 24), { tone: "lo" }));
  // wind vane on its post, pointing downwind
  out.push(S(k.cylinder(VANE[0], VANE[1], 3.5, 0, 1.6, P, 24), { tone: "lo" }));
  out.push(S(k.cylinder(VANE[0], VANE[1], 1.6, 1.6, VANE_Z - 1.6, P, 16), { tone: "mid", crease: "none" }));
  const [ux, uy] = WIND_DIR;
  // the vane is three convex pieces on one pin: tail fin, shaft, head; drawn back to front
  const world = (local) => local.map(([u, v]) => [VANE[0] + u * ux - v * uy, VANE[1] + u * uy + v * ux]);
  const pieces = [
    [[-12, -4.5], [-4, 0], [-12, 4.5]],
    [[-5, -0.9], [5, -0.9], [5, 0.9], [-5, 0.9]],
    [[4, -3], [20, 0], [4, 3]],
  ].map(world);
  pieces.sort((a, b) => k.depthOf([...a.reduce(([x, y], [px, py]) => [x + px / a.length, y + py / a.length], [0, 0]), 0], P) - k.depthOf([...b.reduce(([x, y], [px, py]) => [x + px / b.length, y + py / b.length], [0, 0]), 0], P));
  for (const ring of pieces) out.push(S(k.extrude(ring, VANE_Z, 1.4, P), { tone: "hi", crease: "lo" }));
  out.push(S(k.cylinder(VANE[0], VANE[1], 2, VANE_Z + 1.6, 1.6, P, 20), { tone: "mid" }));
  out.push(D([at([VANE[0], VANE[1], VANE_Z + 3.2])], { size: 0.45, tone: "hi" }));
  return out.join("");
}

function rail() {
  const out = [];
  out.push(S(k.slabOf(RAIL, 0, RAIL_H, P, 3, 0.4), { tone: "mid" }));
  out.push(L(k.lineOnTop([RAIL.x, RAIL.y + RAIL.d / 2], [RAIL.x + RAIL.w, RAIL.y + RAIL.d / 2], RAIL_H, P), { tone: "faint" }));
  return out.join("");
}
function endStop(x) {
  const plan = { x, y: 14, w: 5, d: 16, r: 1 };
  return S(k.slabOf(plan, 0, 8, P, 3, 0.5), { tone: "mid" }) + D([at([x + 2.5, 17, 8]), at([x + 2.5, 27, 8])], { size: 0.45 });
}

function dial() {
  const out = [];
  const [x, y] = DIAL;
  out.push(S(k.cylinder(x, y, 7, 0, 2.5, P, 28), { tone: "lo" }));
  out.push(S(k.cylinder(x, y, 3.5, 2.5, DIAL_Z - 2.5, P, 24), { tone: "mid", crease: "none" }));
  out.push(L([20, 40].map((z) => k.sideArc(x, y, 3.5, z, P, 14)).join(""), { tone: "faint" }));
  out.push(S(k.cylinder(x, y, 4.6, 28, 3, P, 24), { tone: "mid" }));
  out.push(L(k.knurl(x, y, 4.6, 28, 31, 20, P), { tone: "lo" }));
  out.push(S(k.cylinder(x, y, 5, DIAL_Z - 3, 3, P, 28), { tone: "mid" }));
  out.push(S(k.cylinder(x, y, DIAL_R, DIAL_Z, DIAL_H, P, 64, 0.8), { tone: "hi", crease: "lo" }));
  out.push(L(k.knurl(x, y, DIAL_R, DIAL_TOP - 3.2, DIAL_TOP, 88, P, 0.3), { tone: "lo" }));
  out.push(L(k.sideArc(x, y, DIAL_R, DIAL_TOP - 3.2, P, 40), { tone: "faint" }));
  out.push(L(k.ring(x, y, DIAL_R - 2.4, DIAL_TOP, P, 64), { tone: "lo" }));
  const ticks = k.radialTicks(x, y, DIAL_R - 3.4, 30, 5, DIAL_TOP, [1.4, 3], P, SCALE_FROM, SCALE_SPAN);
  out.push(L(ticks.minor, { tone: "lo" }), L(ticks.major, { tone: "mid" }));
  const mark = (aqi, inner, tone, extra = "") => {
    const a = SCALE_FROM + (aqi / AQI_MAX) * SCALE_SPAN;
    const s = Math.sin(a), c = -Math.cos(a);
    return `<path class="iso-line" data-tone="${tone}" d="${k.lineOnTop([x + s * (DIAL_R - 3.4 - inner), y + c * (DIAL_R - 3.4 - inner)], [x + s * (DIAL_R - 3.4), y + c * (DIAL_R - 3.4)], DIAL_TOP, P)}" style="stroke-width:1.2${extra}"/>`;
  };
  out.push(mark(0, 3, "hi"));
  out.push(mark(101, 3.6, "lo", ";stroke:#d79a2c"));
  out.push(mark(M.N95_AQI, 4.4, "red"));
  out.push(L(k.ring(x, y, 1.8, DIAL_TOP, P, 16), { tone: "mid" }));
  out.push(k.faceTextSvg(k.topMatrix([x, y + 9.5], DIAL_TOP, P, "x"), "AQI", { size: 2.6, tone: "lo", anchor: "middle" }));
  // lug on the side holding the crystal
  out.push(S(k.slabOf({ x: x + DIAL_R - 1, y: y - 2.4, w: 4.6, d: 4.8, r: 1.2 }, DIAL_Z + 2, 5, P, 3), { tone: "mid" }));
  return out.join("");
}

function thermometer() {
  const out = [];
  out.push(S(k.slabOf({ x: THERM.x - 2, y: THERM.y - 2, w: THERM.w + 4, d: THERM.d + 8, r: 1 }, 0, 2, P, 3, 0.4), { tone: "lo" }));
  out.push(S(k.slabOf(THERM, 2, 58, P, 1, 0), { tone: "mid" }));
  const face = THERM.y + THERM.d;
  const minor = [], major = [], red = [];
  for (let f = 50; f <= 100; f += 5) {
    const big = f % 10 === 0;
    const hot = f === M.SHADE_F || f === M.HIGH_HEAT_F;
    const len = hot ? 3.4 : big ? 2.6 : 1.6;
    (hot ? red : big ? major : minor).push(k.segment([THERM.x, face, zOfF(f)], [THERM.x + len, face, zOfF(f)], P));
  }
  out.push(L(minor.join(""), { tone: "lo" }), L(major.join(""), { tone: "mid" }));
  out.push(`<path class="iso-line" data-tone="red" d="${red.join("")}" style="stroke-width:1.1"/>`);
  out.push(S(k.cylinder(TUBE[0], TUBE[1], 2.6, 2, 3, P, 20), { tone: "hi" })); // bulb
  out.push(S(k.cylinder(TUBE[0], TUBE[1], TUBE_R, 5, T_Z1 + 2 - 5, P, 16), { tone: "hi", crease: "none" })); // glass
  out.push(S(k.cylinder(TUBE[0], TUBE[1], 2, T_Z1 + 2, 1.6, P, 16), { tone: "mid" })); // cap
  // two clips holding the tube to the plate
  for (const z of [16, 44]) out.push(S(k.slabOf({ x: TUBE[0] - 2.2, y: face - 0.2, w: 4.4, d: 3.6, r: 0.6 }, z, 1.4, P, 2), { tone: "mid", crease: "none" }));
  return out.join("");
}

// --- parts rebuilt in the page each frame (same functions, stringified) ---
function carriageSvg(P) {
  const out = [`<path class="iso-halo" d="${k.haloOf({ x: -16, y: 8, w: 32, d: 30, r: 3 }, 0.2, 0.1, P)}" style="filter:blur(4px)"/>`];
  out.push(k.solidSvg(k.slabOf({ x: -12, y: 16, w: 24, d: 12, r: 1 }, 1.5, 4.5, P, 3, 0.4), { tone: "mid" }));
  out.push(k.solidSvg(k.slabOf({ x: -14, y: 10, w: 28, d: 26, r: 2 }, 6, 7, P, 5, 0.6), { tone: "mid" }));
  out.push(k.lineSvg(k.planOutline({ x: -11, y: 13, w: 22, d: 20, r: 1 }, 13, P, 3), { tone: "faint" }));
  out.push(k.dotsSvg([[-11.5, 11.5], [11.5, 11.5], [-11.5, 34.5], [11.5, 34.5]].map(([x, y]) => k.iso([x, y, 13], P)), { size: 0.4, tone: "lo" }));
  // flag slots
  out.push(k.lineSvg(k.planOutline({ x: -9.6, y: 19.6, w: 13.2, d: 1.8, r: 0.4 }, 13, P, 2), { tone: "lo" }));
  out.push(k.lineSvg(k.planOutline({ x: 4.4, y: 19.6, w: 7.2, d: 1.8, r: 0.4 }, 13, P, 2), { tone: "lo" }));
  // riser and pointer fin reading the hour on the ruler
  out.push(k.solidSvg(k.slabOf({ x: -1, y: 36, w: 2, d: 2, r: 0.4 }, 1, 7, P, 2), { tone: "mid", crease: "none" }));
  out.push(k.solidSvg(k.slabOf({ x: -0.7, y: 36, w: 1.4, d: 15, r: 0.3 }, 1, 0.8, P, 2), { tone: "hi", crease: "none" }));
  // knob on the front
  out.push(k.solidSvg(k.cylinder(0, 38.5, 2.6, 6.5, 5, P, 20), { tone: "mid" }));
  out.push(k.lineSvg(k.knurl(0, 38.5, 2.6, 6.5, 11.5, 16, P), { tone: "lo" }));
  return out.join("");
}
function flagSvg(P, h, lit) {
  return k.solidSvg(k.slabOf({ x: lit ? -9 : 5, y: 20, w: lit ? 12 : 6, d: 1, r: 0.3 }, 13, Math.max(0.3, h), P, 2), { tone: "hi", lit, crease: "none" });
}
function mercurySvg(P, z) {
  return k.solidSvg(k.cylinder(34, -41.5, 0.8, 5, Math.max(0.3, z - 5), P, 12), { tone: "hi", crease: "none" });
}
function plumeSvg(P, length) {
  const [sx, sy] = [-110, -62];
  const [ux, uy] = [0.8472, 0.5312];
  const px = -uy, py = ux;
  const L = Math.max(4, length);
  const wide = 3 + L * 0.22;
  const pts = [];
  pts.push([sx + px * 3, sy + py * 3]);
  for (let i = 0; i <= 8; i++) {
    const a = Math.PI / 2 - (i / 8) * Math.PI;
    pts.push([sx + ux * (L - wide * (1 - Math.cos(a)) * 0.6) + px * wide * Math.sin(a), sy + uy * (L - wide * (1 - Math.cos(a)) * 0.6) + py * wide * Math.sin(a)]);
  }
  pts.push([sx - px * 3, sy - py * 3]);
  const d = k.onTop(pts, 0.25, P, true);
  const streak = (off, share) => k.fadeLineSvg([k.iso([sx + ux * 6 + px * off * 0.2, sy + uy * 6 + py * off * 0.2, 0.3], P), k.iso([sx + ux * L * share + px * off, sy + uy * L * share + py * off, 0.3], P)], { fade: [0, 0.5], tone: "faint" });
  return `<g class="iso-solid"><path class="iso-fill" d="${d}" style="opacity:.55"/><path class="iso-line" data-tone="lo" d="${d}"/></g>` + streak(wide * 0.35, 0.78) + streak(0, 0.84) + streak(-wide * 0.35, 0.72);
}
function paperSvg(P, out) {
  const d = Math.max(0.2, out);
  const plan = { x: 62, y: 75, w: 36, d, r: 0.4 };
  let s = k.solidSvg(k.slabOf(plan, -6, 0.6, P, 2), { tone: "hi", crease: "none" });
  if (d > 6) for (const dy of [3, 8, 13]) if (dy + 3 < d) s += k.lineSvg(k.lineOnTop([66, 75 + dy], [66 + (dy === 8 ? 20 : 28), 75 + dy], -5.4, P), { tone: "lo", free: true });
  return s;
}

const needleAt = (P, aqi) => {
  const a = -2.35619 + (Math.max(0, Math.min(300, aqi)) / 300) * 4.71239;
  const s = Math.sin(a), c = -Math.cos(a);
  return k.lineOnTop([-20 - s * 4, -30 - c * 4], [-20 + s * 21.3, -30 + c * 21.3], 68.2, P);
};

const start = M.stateAt(7);
const svg = k.figureSvg({
  width: WIDTH,
  height: HEIGHT,
  label:
    "A crew lead's bench instrument. A carriage marked 'now' rides a rail along a ruler of the shift hours 07:00 to 17:00. A dial gauge reads the NowCast AQI for the hour under it, with marks at 101 and 151; a thermometer reads °F with marks at 80 and 95. A smoke plume from a small stack reaches the carriage in the early afternoon, the needle crosses 151 and a flag flips up: N95s now. At 17:00 a printed sheet slides out of a slot.",
  body: [
    plate(),
    `<g data-part="plume">${plumeSvg(P, 14 + (start.pm / 75) * 150)}</g>`,
    smokeSide(),
    dial(),
    `<path data-part="needle" class="iso-line" data-tone="hi" data-free="start" d="${needleAt(P, start.aqi)}" style="stroke-width:1.1"/>`,
    thermometer(),
    `<g data-part="mercury">${mercurySvg(P, zOfF(start.temp))}</g>`,
    endStop(RAIL.x - 5),
    rail(),
    `<g data-part="carriage" transform="${k.translateAlong(P, [HOUR_X(7), 0, 0])}">${carriageSvg(P)}<g data-part="flag95">${flagSvg(P, 0.3, true)}</g><g data-part="flag80">${flagSvg(P, 0.3, false)}</g></g>`,
    endStop(RAIL.x + RAIL.w),
    `<g data-part="paper">${paperSvg(P, 0.2)}</g>`,
  ],
});

const strip = (fn) => fn.toString().replace(/\bk\./g, "");
const live = `
${readFileSync(join(HERE, "model.mjs"), "utf8").replace(/^export /gm, "")}
const P = ${JSON.stringify(P)};
const HOUR_X = (h) => -100 + (h - 7) * 20;
const zOfF = (f) => ${T_Z0} + ((f - 50) / 50) * ${T_Z1 - T_Z0};
const flagSvg = ${strip(flagSvg)};
const mercurySvg = ${strip(mercurySvg)};
const plumeSvg = ${strip(plumeSvg)};
const paperSvg = ${strip(paperSvg)};
const needleAt = ${strip(needleAt)};
const stage = document.querySelector(".iso-stage");
const svg = stage.querySelector("svg");
const $ = (name) => svg.querySelector('[data-part="' + name + '"]');
const carriage = $("carriage"), needle = $("needle"), flag95 = $("flag95"), flag80 = $("flag80"), mercury = $("mercury"), plume = $("plume"), paper = $("paper");
const readout = document.querySelector("[data-readout]");
const still = matchMedia("(prefers-reduced-motion: reduce)");
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const TOUR = { run: 12, hold: 2.6, back: 1.6 };
const PERIOD = TOUR.run + TOUR.hold + TOUR.back;
let hour = 7, target = 7;
let needleS = { at: 42, rate: 0 }, f95 = { at: 0.3, rate: 0 }, f80 = { at: 0.3, rate: 0 }, merc = zOfF(58), plumeLen = 30, paperOut = 0.2;
let frame = 0, last = 0, clock = 0, touring = true, visible = false, idleTimer = 0, dragging = false;
let lastKey = "";
const ease = (t) => t * t * (3 - 2 * t);
const tourAt = (t) => {
  const s = t % PERIOD;
  if (s < TOUR.run) return 7 + 10 * (s / TOUR.run);
  if (s < TOUR.run + TOUR.hold) return 17;
  return 17 - 10 * ease((s - TOUR.run - TOUR.hold) / TOUR.back);
};
const spring = (s, want, dt, stiff, drag) => {
  for (let i = 0; i < 4; i++) { s.rate += ((want - s.at) * stiff - s.rate * drag) * dt / 4; s.at += s.rate * dt / 4; }
  if (Math.abs(want - s.at) < 0.004 && Math.abs(s.rate) < 0.004) { s.at = want; s.rate = 0; }
};
function draw(state) {
  carriage.setAttribute("transform", translateAlong(P, [HOUR_X(hour), 0, 0]));
  needle.setAttribute("d", needleAt(P, needleS.at));
  const key = [f95.at.toFixed(2), f80.at.toFixed(2), merc.toFixed(2), plumeLen.toFixed(1), paperOut.toFixed(2)].join("|");
  if (key !== lastKey) {
    lastKey = key;
    flag95.innerHTML = flagSvg(P, f95.at, true);
    flag80.innerHTML = flagSvg(P, f80.at, false);
    mercury.innerHTML = mercurySvg(P, merc);
    plume.innerHTML = plumeSvg(P, plumeLen);
    paper.innerHTML = paperSvg(P, paperOut);
  }
  const text = hourLabel(state.hour) + " · AQI " + Math.round(needleS.at) + " · " + state.temp.toFixed(0) + " °F · " + state.rule;
  if (readout.textContent !== text) readout.textContent = text;
  stage.setAttribute("aria-valuenow", String(Math.round(state.hour * 60)));
  stage.setAttribute("aria-valuetext", text);
}
function tick(now) {
  const dt = last ? Math.min((now - last) / 1000, 1 / 30) : 1 / 60;
  last = now;
  const calm = still.matches;
  if (touring) { clock += dt; target = tourAt(clock); }
  hour = calm || touring ? target : hour + (target - hour) * (1 - Math.exp(-dt / 0.22));
  if (Math.abs(target - hour) < 0.002) hour = target;
  const state = stateAt(hour);
  if (calm) { needleS = { at: state.aqi, rate: 0 }; f95 = { at: state.aqi >= N95_AQI ? 10 : 0.3, rate: 0 }; f80 = { at: state.temp >= SHADE_F ? 6 : 0.3, rate: 0 }; }
  else {
    spring(needleS, state.aqi, dt, 90, 7);
    spring(f95, state.aqi >= N95_AQI ? 10 : 0.3, dt, 260, 14);
    spring(f80, state.temp >= SHADE_F ? 6 : 0.3, dt, 260, 14);
  }
  const k1 = 1 - Math.exp(-dt / 0.35);
  merc += (zOfF(state.temp) - merc) * (calm ? 1 : k1);
  plumeLen += (14 + (state.pm / 75) * 150 - plumeLen) * (calm ? 1 : k1);
  const wantPaper = touring && state.hour >= 16.999 ? ${PAPER_OUT} : 0.2;
  paperOut += (wantPaper - paperOut) * (calm ? 1 : 1 - Math.exp(-dt / 0.3));
  if (Math.abs(wantPaper - paperOut) < 0.02) paperOut = wantPaper;
  draw(state);
  const settled = !touring && hour === target && needleS.rate === 0 && f95.rate === 0 && f80.rate === 0 && Math.abs(zOfF(state.temp) - merc) < 0.01 && paperOut === wantPaper;
  frame = visible && !settled ? requestAnimationFrame(tick) : 0;
}
const run = () => { if (!frame && visible) { last = 0; frame = requestAnimationFrame(tick); } };
const steer = (next) => { touring = false; target = clamp(next, 7, 17); clearTimeout(idleTimer); idleTimer = setTimeout(() => { touring = !still.matches; clock = (target - 7) / 10 * TOUR.run; run(); }, 3600); run(); };
new IntersectionObserver((entries) => { visible = entries[entries.length - 1].isIntersecting; if (visible) run(); }, { rootMargin: "120px 0px" }).observe(stage);
if (still.matches) touring = false;
const hourAtPointer = (event) => {
  const box = svg.getBoundingClientRect();
  const a = iso([HOUR_X(7), 22, 10], P), b = iso([HOUR_X(17), 22, 10], P);
  const sx = (event.clientX - box.left) / box.width * ${WIDTH};
  return 7 + 10 * clamp((sx - a[0]) / (b[0] - a[0]), 0, 1);
};
stage.addEventListener("pointerdown", (event) => { dragging = true; stage.setPointerCapture(event.pointerId); steer(hourAtPointer(event)); });
stage.addEventListener("pointermove", (event) => { if (dragging) steer(hourAtPointer(event)); });
stage.addEventListener("pointerup", () => { dragging = false; });
stage.addEventListener("pointercancel", () => { dragging = false; });
stage.addEventListener("keydown", (event) => {
  let to = null;
  if (event.key === "ArrowRight" || event.key === "ArrowUp") to = Math.round(target) + 1;
  if (event.key === "ArrowLeft" || event.key === "ArrowDown") to = Math.round(target) - 1;
  if (event.key === "Home") to = 7;
  if (event.key === "End") to = 17;
  if (to === null) return;
  event.preventDefault();
  steer(to);
});
draw(stateAt(hour));
`;

const starts = M.startsOf();
const body = k.plateHtml({
  fig: "Fig 1",
  title: "The hour the rule starts",
  hint: "drag the carriage, or let it run",
  readout: `${M.hourLabel(7)} · AQI ${start.aqi} · ${start.temp.toFixed(0)} °F · ${start.rule}`,
  keys: [
    { mark: "lit", label: "Flag: N95s now (NowCast AQI 151+, §5141.1)" },
    { mark: "red", label: "Red marks: AQI 151; 80 °F and 95 °F (§3395)" },
  ],
  caption: `One demo day of hourly PM2.5 (8 to 75 µg/m³) run through the EPA NowCast and the 2024 AQI breakpoints: the carriage is the hour, the needle its NowCast AQI, and the N95 flag flips up at ${M.hourLabel(starts.n95)}, the shade flag at ${M.hourLabel(starts.heat)} when the air reaches 80 °F; at 17:00 the sheet with the day's rules prints.`,
  body: `<div class="iso-stage" tabindex="0" role="slider" aria-label="Crew Air bench: arrow keys move the carriage one hour" aria-valuemin="420" aria-valuemax="1020" aria-valuenow="420">${svg}</div>`,
});

const name = theme === "light" ? "crew-air-light.html" : "crew-air.html";
writeFileSync(join(HERE, name), k.pageHtml({ title: "Crew Air · The hour the rule starts", theme, body, script: kitScript() + live }));
console.log("wrote", name);
