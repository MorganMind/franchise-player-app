import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { ageMult } from "./index.ts";

const settings:any = {
  age: {
    base_schedule: {
      "20":2.00,"21":2.00,"22":1.90,"23":1.80,"24":1.70,"25":1.60,"26":1.50,"27":1.40,
      "28":1.00,"29":1.00,"30":0.95,"31":0.90,"32":0.85,"33":0.80,"34":0.75,"35":0.70,
      "36":0.65,"37":0.60,"38":0.55,"39":0.50,"40":0.45
    },
    cliff_25_27: 0.90,
    cliff_28_plus: 0.75,
    gain: 4.0,
    post29_decay_enabled: true,
    post29_start_age: 29,
    post29_decay_ratio: 0.82,
    floor_age: 40,
    floor_value: 0.0
  }
};

Deno.test("age 29 anchor", () => {
  // (1 + 4*(1-1)) * 0.75 = 0.75
  assertAlmostEquals(ageMult(29, settings), 0.75, 1e-6);
});

Deno.test("age 30 decays from 29", () => {
  // 0.75 * 0.82^(1) ≈ 0.615
  assertAlmostEquals(ageMult(30, settings), 0.75 * Math.pow(0.82, 1), 1e-6);
});

Deno.test("age 35 still > 0 (gradual)", () => {
  // 0.75 * 0.82^(6) ≈ 0.24
  assertAlmostEquals(ageMult(35, settings), 0.75 * Math.pow(0.82, 6), 1e-6);
});

Deno.test("age 40 clamps to 0", () => {
  assertAlmostEquals(ageMult(40, settings), 0.0, 1e-6);
});
