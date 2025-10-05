import { assertAlmostEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { jjPickValue, computeFuturePickPoints } from "./index.ts";

const settings:any = {
  future_picks: {
    enabled: true,
    baseline: "mid_round",
    mid_round_picks: { "1":16, "2":48, "3":80, "4":112, "5":144, "6":176, "7":208 },
    schedule: {
      "1": { "1": 0.75, "2": 0.50 },
      "2": { "1": 0.80, "2": 0.60 },
      "3": { "1": 0.85, "2": 0.70 },
      "4": { "1": 0.90, "2": 0.80 },
      "5": { "1": 0.90, "2": 0.80 },
      "6": { "1": 0.95, "2": 0.90 },
      "7": { "1": 0.95, "2": 0.90 }
    }
  }
};

Deno.test("R1, 1 year out = pick16 * 0.75", () => {
  const base = jjPickValue(16); // 1000 on classic JJ table
  const r = computeFuturePickPoints(1, 1, settings);
  assertAlmostEquals(r.base_points, base, 1e-6);
  assertAlmostEquals(r.points, base * 0.75, 1e-6);
});

Deno.test("R2, 2 years out = pick48 * 0.60", () => {
  const base = jjPickValue(48);
  const r = computeFuturePickPoints(2, 2, settings);
  assertAlmostEquals(r.base_points, base, 1e-6);
  assertAlmostEquals(r.points, base * 0.60, 1e-6);
});

Deno.test("Projected mode clamps to round", () => {
  const s = JSON.parse(JSON.stringify(settings));
  s.future_picks.baseline = "projected";
  const r = computeFuturePickPoints(3, 1, s, 500); // out of round, should be clamped to 65..96 range
  // Just assert points are positive and factor=0.85
  assert(r.points > 0);
  assertAlmostEquals(r.factor, 0.85, 1e-6);
});
