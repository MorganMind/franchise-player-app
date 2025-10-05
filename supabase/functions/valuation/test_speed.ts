import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { speedMultiplier } from "./index.ts";

const settings:any = {
  physical: {
    speed: {
      enabled: true,
      cap_up: { WR:0.12 },
      cap_down_scale: 1.25,
      pivot: { WR:91 },
      steps_up: { WR:8 },
      steps_down: { WR:5 }
    }
  }
};

Deno.test("WR 99 SPD vs 88 SPD", () => {
  const m99 = speedMultiplier("WR", 99, settings); // +8 → 1.12
  const m88 = speedMultiplier("WR", 88, settings); // -3 → 1 - (3/5*0.15) = 0.91
  assertAlmostEquals(m99, 1.12, 1e-6);
  assertAlmostEquals(m88, 0.91, 1e-6);
});


