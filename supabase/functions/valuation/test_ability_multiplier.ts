import { assertAlmostEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { abilitySlotMultiplier } from "./index.ts";

const settings:any = {
  ability_slots: {
    enabled: true,
    thresholds: { "75":1.03,"80":1.06,"85":1.09,"90":1.12,"95":1.15 },
    xf_fourth_at: 95,
    age_band: { "21":1.0, "30":0.74 }
  }
};

Deno.test("Normal/Star → 1.0", () => {
  assertAlmostEquals(abilitySlotMultiplier(95, 21, "Normal", settings), 1.0);
  assertAlmostEquals(abilitySlotMultiplier(95, 21, "Star", settings), 1.0);
});

Deno.test("Superstar 85 @21 → net 1.09", () => {
  const m = abilitySlotMultiplier(85, 21, "Superstar", settings);
  assertAlmostEquals(m, 1.09, 1e-6);
});

Deno.test("X-Factor 95 @21 → net 1.15", () => {
  const m = abilitySlotMultiplier(95, 21, "X-Factor", settings);
  assertAlmostEquals(m, 1.15, 1e-6);
});

Deno.test("Age taper reduces only the extra", () => {
  // 95 XF with age 30 (taper 0.74): 1 + (1.15-1)*0.74 = 1.111
  const m = abilitySlotMultiplier(95, 30, "X-Factor", settings);
  assert(Math.abs(m - (1 + 0.15*0.74)) < 1e-6);
});
