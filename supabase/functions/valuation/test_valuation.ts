import { assertAlmostEquals } from "https://deno.land/std@0.224.0/assert/assert_almost_equals.ts";
import { jjPickValue, nearestPick, qbValueFromOVR, posMult, ageMult, youthBuffer, devTraitMult } from "./index.ts";

// Default settings for testing
const DEFAULT_SETTINGS = {
  pos_spread_scalar: 1.5,
  pos_offsets: {
    "QB": 1.00, "WR": 0.55, "CB": 0.50, "LT": 0.50, "RT": 0.50,
    "LE": 0.60, "RE": 0.60, "LOLB": 0.60, "ROLB": 0.60,
    "DT": 0.40, "FS": 0.45, "SS": 0.45, "TE": 0.40,
    "LG": 0.35, "C": 0.35, "RG": 0.35, "HB": 0.35, "MLB": 0.30,
    "FB": 0.20, "K": 0.15, "P": 0.10, "LS": 0.00
  },
  ovr_curve: { qb60: 2.5, qb99: 6000 },
  age: {
    base_schedule: { 
      "20": 2.00, "21": 2.00, "22": 1.90, "23": 1.80, "24": 1.70, 
      "25": 1.60, "26": 1.50, "27": 1.40, "28": 1.00, "29": 1.00, 
      "30": 0.95, "31": 0.90, "32": 0.85, "33": 0.80, "34": 0.75, 
      "35": 0.70, "36": 0.65, "37": 0.60, "38": 0.55, "39": 0.50, "40": 0.45 
    },
    cliff_25_27: 0.90,
    cliff_28_plus: 0.75,
    gain: 4.0,
    floor_age: 35,
    floor_value: 0.0
  },
  youth_buffer: {
    band: { 
      "20": 1.00, "21": 1.00, "22": 0.85, "23": 0.70, "24": 0.50, 
      "25": 0.35, "26": 0.20, "27": 0.10, "28": 0.00 
    },
    dmax: {
      "QB": 0.20, "WR": 0.14, "CB": 0.14, "LE": 0.14, "RE": 0.14, 
      "LOLB": 0.14, "ROLB": 0.14, "LT": 0.10, "RT": 0.10, "DT": 0.10, 
      "FS": 0.10, "SS": 0.10, "TE": 0.10, "MLB": 0.08, "HB": 0.08, 
      "LG": 0.06, "C": 0.06, "RG": 0.06, "K": 0.03, "P": 0.02, "LS": 0.00
    }
  },
  dev_trait: {
    trait_scores: { "Normal": 0.00, "Star": 2.64, "Superstar": 5.36, "X-Factor": 8.00 },
    dcap: {
      "QB": 0.20, "WR": 0.14, "CB": 0.14, "LE": 0.14, "RE": 0.14, 
      "LOLB": 0.14, "ROLB": 0.14, "LT": 0.10, "RT": 0.10, "DT": 0.10, 
      "FS": 0.10, "SS": 0.10, "TE": 0.10, "MLB": 0.08, "HB": 0.08, 
      "IOL": 0.06, "LG": 0.06, "C": 0.06, "RG": 0.06, "K": 0.03, "P": 0.02, "LS": 0.00
    },
    weights: {
      "QB": {"w_xp": 0.50, "w_abil": 0.50},
      "WR": {"w_xp": 0.50, "w_abil": 0.50},
      "CB": {"w_xp": 0.50, "w_abil": 0.50},
      "LE": {"w_xp": 0.50, "w_abil": 0.50},
      "RE": {"w_xp": 0.50, "w_abil": 0.50},
      "LOLB": {"w_xp": 0.50, "w_abil": 0.50},
      "ROLB": {"w_xp": 0.50, "w_abil": 0.50},
      "LT": {"w_xp": 0.65, "w_abil": 0.35},
      "RT": {"w_xp": 0.65, "w_abil": 0.35},
      "DT": {"w_xp": 0.65, "w_abil": 0.35},
      "FS": {"w_xp": 0.65, "w_abil": 0.35},
      "SS": {"w_xp": 0.65, "w_abil": 0.35},
      "TE": {"w_xp": 0.65, "w_abil": 0.35},
      "MLB": {"w_xp": 0.70, "w_abil": 0.30},
      "HB": {"w_xp": 0.70, "w_abil": 0.30},
      "IOL": {"w_xp": 0.80, "w_abil": 0.20},
      "LG": {"w_xp": 0.80, "w_abil": 0.20},
      "C": {"w_xp": 0.80, "w_abil": 0.20},
      "RG": {"w_xp": 0.80, "w_abil": 0.20},
      "K": {"w_xp": 0.90, "w_abil": 0.10},
      "P": {"w_xp": 0.90, "w_abil": 0.10},
      "LS": {"w_xp": 1.00, "w_abil": 0.00}
    }
  }
};

Deno.test("JJ landmarks", () => {
  // Rough landmarks from our generator
  // spot-check a few known values:
  assertAlmostEquals(jjPickValue(1), 3000, 0.1);
  assertAlmostEquals(jjPickValue(32), 590, 0.1);
  assertAlmostEquals(jjPickValue(88), 150, 1.0);
  assertAlmostEquals(jjPickValue(100), 100, 1.0);
  assertAlmostEquals(jjPickValue(224), 2, 0.1);
});

Deno.test("Position multipliers", () => {
  assertAlmostEquals(posMult("QB", DEFAULT_SETTINGS), 2.50, 0.01);
  assertAlmostEquals(posMult("WR", DEFAULT_SETTINGS), 1.825, 0.01);
  assertAlmostEquals(posMult("CB", DEFAULT_SETTINGS), 1.75, 0.01);
  assertAlmostEquals(posMult("HB", DEFAULT_SETTINGS), 1.525, 0.01);
  assertAlmostEquals(posMult("LS", DEFAULT_SETTINGS), 1.00, 0.01);
});

Deno.test("Age multipliers - key ages", () => {
  // Age 20: base=2.00, no cliff, gain=4.0: 1 + 4*(2.00-1) = 5.0
  assertAlmostEquals(ageMult(20, DEFAULT_SETTINGS), 5.0, 0.01);
  
  // Age 25: base=1.60, cliff=0.90, gain=4.0: 1 + 4*(1.60*0.90-1) = 1 + 4*(1.44-1) = 2.76
  assertAlmostEquals(ageMult(25, DEFAULT_SETTINGS), 2.76, 0.01);
  
  // Age 28: base=1.00, cliff=0.75, gain=4.0: 1 + 4*(1.00*0.75-1) = 1 + 4*(0.75-1) = 0
  assertAlmostEquals(ageMult(28, DEFAULT_SETTINGS), 0.0, 0.01);
  
  // Age 35: floor_age, should be floor_value = 0
  assertAlmostEquals(ageMult(35, DEFAULT_SETTINGS), 0.0, 0.01);
});

Deno.test("Youth buffer", () => {
  // QB age 20: 1 + 0.20 * 1.00 = 1.20
  assertAlmostEquals(youthBuffer("QB", 20, DEFAULT_SETTINGS), 1.20, 0.01);
  
  // WR age 22: 1 + 0.14 * 0.85 = 1.119
  assertAlmostEquals(youthBuffer("WR", 22, DEFAULT_SETTINGS), 1.119, 0.01);
  
  // Age 28+: should be 1.0 (no youth buffer)
  assertAlmostEquals(youthBuffer("QB", 28, DEFAULT_SETTINGS), 1.0, 0.01);
});

Deno.test("Dev trait multipliers", () => {
  // QB age 20 X-Factor: 1 + 0.20 * (0.50*1.00 + 0.50) * 8.00 = 1 + 0.20 * 1.0 * 8.0 = 2.6
  assertAlmostEquals(devTraitMult("QB", 20, "X-Factor", DEFAULT_SETTINGS), 2.6, 0.01);
  
  // WR age 25 Star: 1 + 0.14 * (0.50*0.35 + 0.50) * 2.64 = 1 + 0.14 * 0.675 * 2.64 = 1.249
  assertAlmostEquals(devTraitMult("WR", 25, "Star", DEFAULT_SETTINGS), 1.249, 0.01);
  
  // Normal dev trait should be 1.0
  assertAlmostEquals(devTraitMult("QB", 20, "Normal", DEFAULT_SETTINGS), 1.0, 0.01);
});

Deno.test("QB value from OVR", () => {
  // OVR 60 should be close to qb60 = 2.5
  assertAlmostEquals(qbValueFromOVR(60, DEFAULT_SETTINGS), 2.5, 0.1);
  
  // OVR 99 should be close to qb99 = 6000
  assertAlmostEquals(qbValueFromOVR(99, DEFAULT_SETTINGS), 6000, 10);
  
  // OVR 80 should be somewhere in between
  const val80 = qbValueFromOVR(80, DEFAULT_SETTINGS);
  if (val80 < 2.5 || val80 > 6000) {
    throw new Error(`OVR 80 value ${val80} is outside expected range [2.5, 6000]`);
  }
});

Deno.test("Nearest pick", () => {
  const result1 = nearestPick(3000);
  if (result1.pick !== 1) {
    throw new Error(`Expected pick 1 for 3000 points, got ${result1.pick}`);
  }
  
  const result2 = nearestPick(2);
  if (result2.pick !== 224) {
    throw new Error(`Expected pick 224 for 2 points, got ${result2.pick}`);
  }
});
