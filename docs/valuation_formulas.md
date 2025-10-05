# Valuation Formulas (Canonical Spec)

This document is the **source of truth** for how values are calculated by the `valuation` Edge Function. It mirrors the code in `supabase/functions/valuation/index.ts`.

---

## 0) Notation
- `OVR ∈ [60, 99]`, `age ∈ [20, 40]`
- `pos ∈ {QB, WR, CB, ...}`
- Settings are loaded from `valuation_settings`.

Final stack:

V_final(OVR, age, pos, dev) =
BaseJJ(OVR) // reverse-JJ OVR curve → QB-anchored
× PosMult(pos) // position tier spread
× AgeMult(age) // base schedule → apply cliffs → apply gain → clamp floor
× YouthBuffer(pos, age) // extra youth upside by position
× DevTraitMult(pos, age, dev) // dev trait (position-aware, age-banded)


---

## 1) Reverse JJ OVR Curve (QB-anchored)
We do **not** linearly interpolate between 60 and 99. We use the **reverse Jimmy Johnson shape**:

1. Map `OVR → pick`:

t = clamp01( (OVR - 60) / 39 )
p(OVR) = round( 224 - t * 223 ) // 60→224, 99→1

2. Let `JJ[p]` be the classic Jimmy Johnson pick value (1..224). Normalize:

g = ( JJ[p] - JJ[224] ) / ( JJ[1] - JJ[224] ) // g ∈ [0,1]

3. Blend between **QB60** and **QB99** anchors:

V_QB(OVR) = qb60 + (qb99 - qb60) * g

Defaults: `qb60 = 2.5`, `qb99 = 6000`.

4. Convert to a **position-neutral base** by dividing out the QB position multiplier:

BaseJJ(OVR) = V_QB(OVR) / PosMult(QB)


---

## 2) Position Multiplier

PosMult(pos) = 1 + pos_spread_scalar * pos_offset[pos]

Default `pos_spread_scalar = 1.5`. Example:
- QB: `1 + 1.5×1.00 = 2.50`
- WR: `1 + 1.5×0.55 = 1.825`
- CB/OT: `1 + 1.5×0.50 = 1.75`
- HB/IOL: `1 + 1.5×0.35 = 1.525`
(Offsets are configurable per position.)

---

## 3) Age Multiplier (order matters)
Age follows this **exact** sequence:

1) **Start from base schedule**: `base = base_schedule[age]`  
   e.g. `20:2.00, 21:2.00, 22:1.90, 23:1.80, 24:1.70, 25:1.60, 26:1.50, 27:1.40, 28:1.00, 29:0.95, 30:0.90, 31:0.85, 32:0.80, 33:0.75, 34:0.70, 35:0.65, 36:0.60, 37:0.55, 38:0.50, 39:0.45, 40:0.40`

2) **Apply gain around 1.0**: `m = 1 + gain * (base - 1)`

3) **Apply cliff**: `m = m * cliff_mod(age)`  
   where `cliff_mod(age) = (25–27) ? cliff_25_27 : (age ≥ 28) ? cliff_28_plus : 1.0`

4) **Floor/clamp**: `if age ≥ floor_age → m = floor_value`; finally `m = max(0, m)`

Defaults: `gain = 4.0`, `cliff_25_27 = 0.90`, `cliff_28_plus = 0.85`, `floor_age = 40`, `floor_value = 0`.

**Examples:**
- With `gain=4.0`, `base(28)=1.00`, `cliff_28_plus=0.85`:  
  `m = (1 + 4*(1−1)) * 0.85 = 0.85`
- With `base(30)=0.90`:  
  `m = (1 + 4*(0.90−1)) * 0.85 = 0.60 * 0.85 = 0.51`
- With `base(35)=0.65`:  
  `m = (1 + 4*(0.65−1)) * 0.85 = 0.40 * 0.85 = 0.34`

> This order keeps a real 28+ penalty but avoids zeroing typical ages. The **gain is applied first**, then the cliff modifier.

---

## 4) Youth Buffer (positional growth potential)
Extra upside for very young players, per position:

YouthBuffer(pos, age) = 1 + Dmax[pos] * Band(age)

- `Band(age)`: 20–21:1.00, 22:0.85, 23:0.70, 24:0.50, 25:0.35, 26:0.20, 27:0.10, ≥28:0.00
- `Dmax[pos]` defaults: QB:0.20; WR/CB/EDGE:0.14; OT/S/DT/TE:0.10; MLB/HB:0.08; IOL:0.06; K:0.03; P:0.02; LS:0.00

---

## 5) Dev Trait Multiplier (position-aware; XP vs abilities)

DevTraitMult(pos, age, trait) =
1 + Dcap[pos] * ( w_xp[pos] * DevBand(age) + w_abil[pos] ) * TraitScore[trait]

- `TraitScore` (aggressive defaults): Normal:0.00, Star:2.64, Superstar:5.36, X-Factor:8.00
- `DevBand(age)` uses the same band as §4 (progression fades by 28).
- `Dcap[pos]` defaults like Dmax (QB 0.20 … K 0.03, etc.).
- Weights default:
  - QB/WR/CB/EDGE: `w_xp=0.50`, `w_abil=0.50`
  - OT/S/DT/TE: `0.65 / 0.35`
  - MLB/HB: `0.70 / 0.30`
  - IOL: `0.80 / 0.20`
  - K/P: `0.90 / 0.10`
  - LS: `1.00 / 0.00`

---

## 6) Nearest JJ Pick (for UX)
Given points `P`, the function scans picks 1..224 and returns the closest:
- `pick`, `round`, `pick_in_round`, and `nearest_points`.

---

## 7) Reference Implementation
See `supabase/functions/valuation/index.ts`:
- `jjPickValue`, `nearestPick`
- `qbValueFromOVR` (reverse JJ mapping)
- `posMult`, `ageMult`, `youthBuffer`, `devTraitMult`
- `POST /compute` returns `{ value, nearest_pick, round, pick_in_round, nearest_points, details }`

---

## 8) Common Pitfalls
- **Not linear:** OVR curve uses **reverse JJ**, not a line.
- **Cliffs before gain:** `AgeMult` multiplies cliff first, then applies `gain`.
- **Floor at 35+:** With defaults, **35+ clamps to 0** (no negative values).

---
