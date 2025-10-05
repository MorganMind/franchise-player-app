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
    floor_age: 35,
    floor_value: 0.0
  }
};

Deno.test("age 28 keeps penalty but not zero", () => {
  // (1 + 4*(1-1)) * 0.75 = 0.75
  assertAlmostEquals(ageMult(28, settings), 0.75, 1e-6);
});

Deno.test("age 30 > 0 with 28+ cliff", () => {
  // (1 + 4*(0.95-1)) * 0.75 = 0.8 * 0.75 = 0.60
  assertAlmostEquals(ageMult(30, settings), 0.60, 1e-6);
});

Deno.test("age 35 floors to 0", () => {
  assertAlmostEquals(ageMult(35, settings), 0.0, 1e-6);
});
