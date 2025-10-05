import { assertAlmostEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { softCap } from "./index.ts";

Deno.test("softCap identity below threshold", () => {
  const v = softCap(4000, 6000, 18000);
  assertAlmostEquals(v, 4000, 1e-6);
});

Deno.test("softCap compresses and stays ≤ vmax", () => {
  const v = softCap(93600, 6000, 18000);
  assert(v <= 18000);
  // ~17,992 with these params; allow small tolerance
  assert(Math.abs(v - 18000) < 50);
});

Deno.test("moderate top-end slightly compressed", () => {
  const v = softCap(11840, 6000, 18000);
  // ≈ 10,630 (ballpark); just assert it's between threshold and vmax
  assert(v > 6000 && v < 18000);
});
