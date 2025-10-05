import { assertAlmostEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { ageMult } from "./index.ts";

const settings:any = {
  age: {
    base_schedule: { "29":1.0, "30":0.95, "31":0.90, "32":0.85, "33":0.80, "34":0.75, "35":0.70, "36":0.65, "37":0.60, "38":0.55, "39":0.50 },
    cliff_25_27: 0.90, cliff_28_plus: 0.75,
    gain: 4.0, post29_decay_enabled: true, post29_start_age: 29, post29_decay_ratio: 0.82,
    floor_age: 35, floor_value: 0.0, penalty_relief_over28: 0.0
  },
  pos_longevity: {
    start_age: { "HB": 28, "QB": 31, "K": 31, "P": 31, "LT": 30, "LG": 30, "C": 30, "RG": 30, "RT": 30 },
    floor_age: { "HB": 33, "QB": 39, "LT": 37, "LG": 37, "C": 37, "RG": 37, "RT": 37 }
  }
};

Deno.test("HB floor at 33", () => {
  assertAlmostEquals(ageMult(33, "HB", settings), 0.0, 1e-6);
  assert(ageMult(32, "HB", settings) > 0);
});

Deno.test("QB floor at 39", () => {
  assertAlmostEquals(ageMult(39, "QB", settings), 0.0, 1e-6);
  assert(ageMult(38, "QB", settings) > 0);
});

Deno.test("OL floor at 37", () => {
  assertAlmostEquals(ageMult(37, "LT", settings), 0.0, 1e-6);
  assert(ageMult(36, "LT", settings) > 0);
});

Deno.test("Default others floor 35", () => {
  assertAlmostEquals(ageMult(35, "WR", settings), 0.0, 1e-6);
  assert(ageMult(34, "WR", settings) > 0);
});


