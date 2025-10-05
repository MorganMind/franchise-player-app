import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { ageMult } from "./index.ts";

const settings:any = {
  age: {
    base_schedule: {
      "20":2.00,"21":2.00,"22":1.90,"23":1.80,"24":1.70,"25":1.60,"26":1.50,"27":1.40,
      "28":1.00,"29":0.95,"30":0.90,"31":0.85,"32":0.80,"33":0.75,"34":0.70,"35":0.65,
      "36":0.60,"37":0.55,"38":0.50,"39":0.45,"40":0.40
    },
    cliff_25_27: 0.90,
    cliff_28_plus: 0.85,
    gain: 4.0,
    floor_age: 40,
    floor_value: 0.0
  }
};

Deno.test("age 28 keeps penalty but not zero", () => {
  // (1 + 4*(1-1)) * 0.85 = 0.85
  assertAlmostEquals(ageMult(28, settings), 0.85, 1e-6);
});

Deno.test("age 30 > 0 with 28+ cliff", () => {
  // (1 + 4*(0.90-1)) * 0.85 = 0.60 * 0.85 = 0.51
  assertAlmostEquals(ageMult(30, settings), 0.51, 1e-6);
});

Deno.test("age 35 gradual decline", () => {
  // (1 + 4*(0.65-1)) * 0.85 = 0.40 * 0.85 = 0.34
  assertAlmostEquals(ageMult(35, settings), 0.34, 1e-6);
});

Deno.test("age 40 floors to 0", () => {
  assertAlmostEquals(ageMult(40, settings), 0.0, 1e-6);
});
