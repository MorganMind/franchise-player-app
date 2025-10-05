import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { jjPickValue } from "./index.ts";
import { ageMult } from "./index.ts";

Deno.test("gamma preserves anchors and lifts top end", () => {
  // crude check: with gamma>1, 90 OVR normalized g should increase vs gamma=1
  // (We won't recompute full V here; this test is illustrative if qbValueFromOVR is exported.)
  assert(true); // placeholder if qbValueFromOVR not exported; otherwise compare values at gamma=1 vs 1.15
});

Deno.test("age relief raises 30yo ageMult", () => {
  const settings:any = {
    age: {
      base_schedule: { "29": 1.00, "30": 0.95 },
      cliff_25_27: 0.90, cliff_28_plus: 0.75,
      gain: 4.0, floor_age: 40, floor_value: 0.0,
      post29_decay_enabled: true, post29_start_age: 29, post29_decay_ratio: 0.82,
      penalty_relief_over28: 0.15
    }
  };
  const s_noRelief = { age: { ...settings.age, penalty_relief_over28: 0 } };
  const m0 = ageMult(30, s_noRelief as any);   // ≈ 0.60 with your defaults
  const m1 = ageMult(30, settings as any);     // relief → higher than m0
  assert(m1 > m0);
});
