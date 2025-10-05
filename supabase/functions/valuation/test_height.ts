import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { heightMultiplier } from "./index.ts";

const settings:any = {
  physical: {
    height: {
      enabled: true,
      inches_to_cap: 4,
      cap_down_scale: 1.4,
      baselines_in: { QB:73 },
      cap_up: { QB:0.05 }
    }
  }
};

Deno.test("QB: 5'11 (71 in) vs 6'5 (77 in)", () => {
  const mShort = heightMultiplier("QB", 71, settings); // Δ=-2 → 1 - min(0.07, 2*(0.07/4)) = 1 - 0.035 = 0.965
  const mTall  = heightMultiplier("QB", 77, settings); // Δ=+4 → 1 + min(0.05, 4*(0.05/4)) = 1 + 0.05 = 1.05
  assertAlmostEquals(mShort, 0.965, 1e-6);
  assertAlmostEquals(mTall,  1.050, 1e-6);
});


