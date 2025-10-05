import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { thpMultiplier } from "./index.ts";

const settings:any = { physical: { thp: {
  enabled: true, cap_up_qb: 0.10, cap_down_scale: 1.20, pivot_qb: 93, steps_up_qb: 6, steps_down_qb: 5
}}};

Deno.test("QB THP 99 hits +10%", () => {
  const m = thpMultiplier("QB", 99, settings);
  assertAlmostEquals(m, 1.10, 1e-6);
});

Deno.test("QB THP 88 hits ~-12% cap", () => {
  const m = thpMultiplier("QB", 88, settings);
  assertAlmostEquals(m, 0.88, 1e-6);
});

Deno.test("Non-QB ignores THP", () => {
  const m = thpMultiplier("WR", 99, settings);
  assertAlmostEquals(m, 1.00, 1e-6);
});


