/**
 * Valuation pipeline (canonical; matches docs/valuation_formulas.md):
 * V = BaseJJ(OVR) × PosMult(pos) × AgeMult(age) × YouthBuffer(pos, age) × DevTraitMult(pos, age, trait)
 *
 * AgeMult ORDER (important):
 *   1) m = 1 + gain * (base_schedule[age] - 1)
 *   2) m = m * cliff_mod(age)
 *   3) if (age >= 30) m = m(29) * decay_ratio^(age-29)
 *   4) if (age >= floor_age) m = floor_value
 *   return max(0, m)
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

type Settings = {
  pos_spread_scalar: number;
  pos_offsets: Record<string, number>;
  ovr_curve: { qb60: number; qb99: number };
  age: {
    base_schedule: Record<string, number>;
    cliff_25_27: number;
    cliff_28_plus: number;
    gain: number;
    floor_age: number;
    floor_value: number;
  };
  youth_buffer: {
    band: Record<string, number>;
    dmax: Record<string, number>;
  };
  dev_trait: {
    trait_scores: Record<string, number>;
    dcap: Record<string, number>;
    weights: Record<string, { w_xp: number; w_abil: number }>;
  };
  gravity?: { enabled: boolean; threshold: number; vmax: number };
  future_picks?: {
    enabled: boolean;
    baseline: "mid_round" | "projected";
    mid_round_picks: Record<string, number>;
    schedule: Record<string, Record<string, number>>;
  };
};

export function jjPickValue(pick: number): number {
  // Classic JJ chart (programmatic)
  const r1=[3000,2600,2200,1800,1700,1600,1500,1400,1350,1300,1250,1200,1150,1100,1050,1000,950,900,875,850,800,780,760,740,720,700,680,660,640,620,600,590];
  if (pick<1) pick=1; if (pick>224) pick=224;
  if (pick<=32) return r1[pick-1];
  let val=590; // pick 32 value
  for (let p=33;p<=224;p++){
    if (p<=60) val-=10;
    else if (p<=64) val-=8;
    else if (p<=96) val-=5;
    else if (p<=108) val-=4;
    else if (p<=128) val-=3;
    else if (p<=160) val-=2;
    else val-=1;
    if (p===pick) return val;
  }
  return 2;
}

export function nearestPick(points: number){
  let bestPick=224, bestDiff=Infinity, bestVal=2;
  for (let p=1;p<=224;p++){
    const v=jjPickValue(p);
    const d=Math.abs(v-points);
    if (d<bestDiff){bestDiff=d; bestPick=p; bestVal=v;}
  }
  const round = Math.floor((bestPick-1)/32)+1;
  const pick_in_round = ((bestPick-1)%32)+1;
  return {pick:bestPick, round, pick_in_round, points:bestVal};
}

// Reverse JJ OVR → QB value with anchors qb60,qb99
export function qbValueFromOVR(ovr:number, settings:Settings){
  const { qb60, qb99 } = settings.ovr_curve;
  const t = Math.max(0, Math.min(1, (ovr-60)/39));
  const p = Math.round(224 - t*223); // 60→224, 99→1
  const jj1 = jjPickValue(1), jj224 = jjPickValue(224);
  const g = (jjPickValue(p) - jj224) / (jj1 - jj224);
  return qb60 + (qb99 - qb60) * g;
}

// Position multiplier
export function posMult(pos:string, settings:Settings){
  const o = settings.pos_offsets[pos] ?? 0;
  return 1 + settings.pos_spread_scalar * o;
}

// Soft cap (gravity) function
function softCap(V: number, T: number, Vmax: number) {
  if (!Number.isFinite(V) || V <= 0) return 0;
  if (V <= T) return V;
  const C = Math.max(1, Vmax - T);
  const d = V - T;
  const out = T + C * (1 - Math.exp(-d / C));
  return Math.min(out, Vmax);
}
export { softCap }; // for tests

// Future pick helpers
function roundRange(roundNum: number): { start: number; end: number } {
  const r = Math.max(1, Math.min(7, Math.floor(roundNum)));
  const start = (r - 1) * 32 + 1;
  const end = r * 32;
  return { start, end };
}

function baselinePickForRound(roundNum: number, settings: Settings, projected_pick?: number): number {
  const { start, end } = roundRange(roundNum);
  const fp = settings.future_picks!;
  if ((fp.baseline ?? "mid_round") === "projected" && projected_pick) {
    // snap into round range if caller gives a projected pick in that round
    const p = Math.max(start, Math.min(end, Math.floor(projected_pick)));
    return p;
    // NOTE: If a projected pick outside the round is given, we clamp to the round boundaries.
  }
  // mid-round anchor (configurable per round)
  const mid = fp.mid_round_picks?.[String(roundNum)];
  if (typeof mid === "number") return Math.max(start, Math.min(end, Math.floor(mid)));
  // fallback: exact mid of the round
  return Math.floor((start + end) / 2);
}

function futurePickFactor(roundNum: number, years_out: number, settings: Settings): number {
  const k = Math.max(0, Math.min(2, Math.floor(years_out))); // Madden limit
  if (k === 0) return 1.0;
  const sched = settings.future_picks?.schedule ?? {};
  const row = sched[String(roundNum)] ?? {};
  const f = row[String(k)];
  if (typeof f === "number" && f > 0) return f;
  // default conservative fallback if not found
  return k === 1 ? 0.85 : 0.70;
}

export function computeFuturePickPoints(
  roundNum: number,
  years_out: number,
  settings: Settings,
  projected_pick?: number
) {
  const p0 = baselinePickForRound(roundNum, settings, projected_pick);
  const basePts = jjPickValue(p0);
  const factor = futurePickFactor(roundNum, years_out, settings);
  const points = basePts * factor;
  return { points, baseline_pick: p0, factor, base_points: basePts };
}

// Age multiplier (with cliffs, gain, and floor)
export function ageMult(age:number, settings:Settings){
  const a = Math.max(20, Math.min(40, Math.floor(age)));

  const base = settings.age.base_schedule[String(a)] ?? 1.0;
  const cliff = (a>=28) ? settings.age.cliff_28_plus
               : (a>=25 && a<=27) ? settings.age.cliff_25_27
               : 1.0;

  // 1) Apply gain around 1.0
  let m = 1 + (settings.age.gain ?? 4.0) * (base - 1);

  // 2) Then apply cliff
  m = m * cliff;

  // 3) Post-29 geometric decay (smooth decline 30..39)
  //    m(29) is the anchor; for age>=30 use m(29) * ratio^(age-29)
  const decayEnabled = settings.age.post29_decay_enabled ?? true;
  const startAge = settings.age.post29_start_age ?? 29;
  const ratio = settings.age.post29_decay_ratio ?? 0.82; // ~18% drop per year by default

  if (decayEnabled && a >= (startAge + 1)) {
    // compute m at the anchor age using the same rules
    const baseStart = settings.age.base_schedule[String(startAge)] ?? 1.0;
    const cliffStart = (startAge>=28) ? (settings.age.cliff_28_plus ?? 1.0)
                     : (startAge>=25 && startAge<=27) ? (settings.age.cliff_25_27 ?? 1.0)
                     : 1.0;
    const mStart = (1 + (settings.age.gain ?? 4.0) * (baseStart - 1)) * cliffStart;
    const k = a - startAge;
    m = mStart * Math.pow(ratio, k);
  }

  // 4) Floor clamp (e.g., age >= 40 => 0)
  const floorAge = settings.age.floor_age ?? 40;
  const floorValue = settings.age.floor_value ?? 0.0;
  if (a >= floorAge) m = floorValue;

  // never negative
  return Math.max(0, m);
}

// Youth growth buffer (per-position, age banded)
export function youthBuffer(pos:string, age:number, settings:Settings){
  const a = Math.max(20, Math.min(28, Math.floor(age)));
  const band = settings.youth_buffer.band[String(a)] ?? 0;
  const dmax = settings.youth_buffer.dmax[pos] ?? 0;
  return 1 + dmax * band;
}

// Dev trait multiplier (position-aware, XP vs abilities, age-banded XP)
export function devTraitMult(pos:string, age:number, trait:string, settings:Settings){
  const tScore = settings.dev_trait.trait_scores[trait] ?? 0;
  const dcap = settings.dev_trait.dcap[pos] ?? settings.dev_trait.dcap["IOL"] ?? 0;
  const w = settings.dev_trait.weights[pos] ?? { w_xp:0.5, w_abil:0.5 };
  const devBand =
    (age<=21)?1.00:
    (age===22)?0.85:
    (age===23)?0.70:
    (age===24)?0.50:
    (age===25)?0.35:
    (age===26)?0.20:
    (age===27)?0.10:0.00;
  return 1 + dcap * (w.w_xp * devBand + w.w_abil) * tScore;
}

async function getSettings(franchise_id?:string): Promise<Settings>{
  // Try franchise row, else fall back to default
  if (franchise_id){
    const { data, error } = await supabase
      .from("valuation_settings")
      .select("settings")
      .eq("franchise_id", franchise_id)
      .limit(1)
      .maybeSingle();
    if (!error && data?.settings) return data.settings as Settings;
  }
  const { data: def, error: defErr } = await supabase
    .from("valuation_settings")
    .select("settings")
    .eq("label","default")
    .limit(1)
    .maybeSingle();
  if (defErr || !def?.settings) throw new Error("settings_not_found");
  return def.settings as Settings;
}

async function upsertSettings(payload:{franchise_id?:string; settings:Partial<Settings>}){
  const fid = payload.franchise_id ?? null;
  // Load existing
  let existing: Settings | null = null;
  if (fid){
    const { data } = await supabase
      .from("valuation_settings")
      .select("id,settings")
      .eq("franchise_id", fid)
      .limit(1)
      .maybeSingle();
    if (data?.settings) existing = data.settings as Settings;
  } else {
    const { data } = await supabase
      .from("valuation_settings")
      .select("id,settings")
      .eq("label","default")
      .limit(1)
      .maybeSingle();
    if (data?.settings) existing = data.settings as Settings;
  }

  const merged = existing ? deepMerge(existing, payload.settings) : payload.settings;
  // Upsert row
  if (fid){
    const { error } = await supabase
      .from("valuation_settings")
      .upsert({ franchise_id: fid, settings: merged }, { onConflict: "franchise_id" });
    if (error) throw error;
  } else {
    const { error } = await supabase
      .from("valuation_settings")
      .upsert({ label: "default", settings: merged }, { onConflict: "label" });
    if (error) throw error;
  }
  return merged;
}

// shallow+nested merge for JSON structures
function deepMerge<T>(base: any, patch: any): T {
  if (patch === null || patch === undefined) return base;
  if (typeof patch !== "object" || Array.isArray(patch)) return patch as T;
  const out: any = Array.isArray(base) ? [...base] : { ...(base ?? {}) };
  for (const k of Object.keys(patch)) {
    const pv = (patch as any)[k];
    const bv = (base ?? {})[k];
    out[k] = (typeof pv === "object" && !Array.isArray(pv)) ? deepMerge(bv, pv) : pv;
  }
  return out as T;
}

function ok(body: unknown, status=200){
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin":"*" }});
}

serve(async (req) => {
  try{
    const url = new URL(req.url);
    if (req.method === "OPTIONS"){
      return new Response("", { status: 204, headers: { "Access-Control-Allow-Origin":"*", "Access-Control-Allow-Methods":"GET,POST,PATCH,OPTIONS", "Access-Control-Allow-Headers":"Content-Type,Authorization" }});
    }

    // GET /settings?franchise_id=...
    if (req.method === "GET" && url.pathname.endsWith("/settings")){
      const fid = url.searchParams.get("franchise_id") ?? undefined;
      const s = await getSettings(fid);
      return ok({ ok:true, settings: s });
    }

    // PATCH /settings  { franchise_id?, settings }
    if (req.method === "PATCH" && url.pathname.endsWith("/settings")){
      const body = await req.json().catch(() => ({}));
      const merged = await upsertSettings(body);
      return ok({ ok:true, settings: merged });
    }

    // POST /compute { ovr, age, pos, dev, franchise_id? }
    if (req.method === "POST" && url.pathname.endsWith("/compute")){
      const body = await req.json();
      const { ovr, age, pos, dev, franchise_id } = body ?? {};
      if (typeof ovr !== "number" || typeof age !== "number" || !pos || !dev){
        return ok({ ok:false, error:"invalid_payload" }, 400);
      }
      const s = await getSettings(franchise_id);

      // OVR → QB value (reverse JJ), then get common base by dividing out QB's position multiplier
      const qbVal = qbValueFromOVR(ovr, s);
      const qbMult = posMult("QB", s); // typically 1 + s.pos_spread_scalar * 1.0 = 2.5
      const base = qbVal / qbMult;

      // Multipliers
      const mPos = posMult(pos, s);
      const mAge = ageMult(age, s);
      const mYouth = youthBuffer(pos, age, s);
      const mDev = devTraitMult(pos, age, dev, s);

      let value = base * mPos * mAge * mYouth * mDev;

      // ---- Global Gravity (soft cap) ----
      // Defaults: enabled, threshold=6000, vmax=18000
      const g = s.gravity ?? { enabled: true, threshold: 6000, vmax: 18000 };
      if (g.enabled) {
        const T = Number.isFinite(g.threshold) ? g.threshold : 6000;
        const Vmax = Number.isFinite(g.vmax) ? g.vmax : 18000;
        value = softCap(value, T, Vmax);
      }

      const nearest = nearestPick(value);
      return ok({
        ok:true,
        value,
        nearest_pick: nearest.pick,
        round: nearest.round,
        pick_in_round: nearest.pick_in_round,
        nearest_points: nearest.points,
        details: {
          qb_base_value: qbVal,
          base_after_dividing_qb_mult: base,
          multipliers: { pos:mPos, age:mAge, youth:mYouth, dev:mDev },
          gravity: g
        }
      });
    }

    // POST /pick  { round: 1..7, years_out: 0|1|2, projected_pick?: number }
    if (req.method === "POST" && url.pathname.endsWith("/pick")) {
      const body = await req.json().catch(() => ({}));
      const roundNum = Number(body.round);
      const yearsOut = Number(body.years_out ?? body.yearsOut ?? 0);
      const projected = body.projected_pick ?? body.projectedPick;

      if (!(roundNum >= 1 && roundNum <= 7)) {
        return ok({ ok:false, error:"invalid_round" }, 400);
      }
      if (!(yearsOut >= 0 && yearsOut <= 2)) {
        return ok({ ok:false, error:"invalid_years_out_madden_limit_0_2" }, 400);
      }

      const s = await getSettings(body.franchise_id ?? body.franchiseId ?? undefined);
      if (!s.future_picks?.enabled) {
        return ok({ ok:false, error:"future_picks_disabled" }, 400);
      }

      const calc = computeFuturePickPoints(roundNum, yearsOut, s, projected ? Number(projected) : undefined);
      const nearest = nearestPick(calc.points);
      return ok({
        ok: true,
        round: roundNum,
        years_out: yearsOut,
        baseline_pick: calc.baseline_pick,
        factor: calc.factor,
        base_points: calc.base_points,
        value: calc.points,
        nearest_pick: nearest.pick,
        pick_in_round: nearest.pick_in_round,
        round_of_nearest: nearest.round,
        nearest_points: nearest.points
      });
    }

    return ok({ ok:false, error:"not_found" }, 404);
  } catch (e){
    return ok({ ok:false, error:String(e) }, 500);
  }
});
