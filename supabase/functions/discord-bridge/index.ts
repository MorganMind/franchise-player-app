/**
 * Supabase Edge Function: discord-bridge
 * Endpoints:
 *  - POST /register_franchise
 *  - POST /claim_team
 *  - POST /set_active
 *
 * Security: HMAC-SHA256 signature:
 *   Headers:
 *     X-FP-Timestamp: unix seconds
 *     X-FP-Signature: hex(HMAC_SHA256(FP_BRIDGE_SECRET, `${timestamp}.${body}`))
 *   Reject if clock skew > 300s
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encode as hexEncode } from "https://deno.land/std@0.224.0/encoding/hex.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FP_BRIDGE_SECRET = Deno.env.get("FP_BRIDGE_SECRET")!;

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

function hmacSha256(key: string, msg: string): string {
  const enc = new TextEncoder();
  const cryptoKey = crypto.subtle.importKey(
    "raw",
    enc.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  // deno-lint-ignore no-explicit-any
  //@ts-ignore - top-level await for subtle.sign is fine in Deno
  return cryptoKey.then((k: CryptoKey) => crypto.subtle.sign("HMAC", k, enc.encode(msg)))
    .then((sig: ArrayBuffer) => {
      const bytes = new Uint8Array(sig);
      return Array.from(hexEncode(bytes)).map((c) => String.fromCharCode(c)).join("");
    });
}

async function verify(req: Request, rawBody: string): Promise<Response | null> {
  try {
    const ts = req.headers.get("X-FP-Timestamp");
    const sig = req.headers.get("X-FP-Signature");
    if (!ts || !sig) return new Response("Missing auth headers", { status: 401 });

    const now = Math.floor(Date.now() / 1000);
    const tsNum = parseInt(ts, 10);
    if (isNaN(tsNum) || Math.abs(now - tsNum) > 300) {
      return new Response("Timestamp skew", { status: 401 });
    }

    const expected = await hmacSha256(FP_BRIDGE_SECRET, `${ts}.${rawBody}`);
    if (expected !== sig) {
      return new Response("Bad signature", { status: 401 });
    }
    return null;
  } catch {
    return new Response("Auth error", { status: 401 });
  }
}

async function handleRegisterFranchise(payload: any) {
  const {
    guild_id,
    franchise: { name: franchiseName } = {},
    franchise_role_id,
    team_roles, // [{team_code, role_id}]
  } = payload ?? {};

  if (!guild_id || !franchiseName || !franchise_role_id || !Array.isArray(team_roles)) {
    return Response.json({ ok: false, error: "invalid_payload" }, { status: 400 });
  }

  // Ensure server row
  let { data: server } = await supabase
    .from("servers")
    .select("*")
    .eq("discord_guild_id", guild_id)
    .single();

  if (!server) {
    const { data: inserted, error: insErr } = await supabase
      .from("servers")
      .insert({ name: `Guild ${guild_id}`, discord_guild_id: guild_id })
      .select("*")
      .single();
    if (insErr) return Response.json({ ok: false, error: insErr.message }, { status: 400 });
    server = inserted;
  }

  // Upsert franchise row
  let { data: franchise } = await supabase
    .from("franchises")
    .select("*")
    .eq("server_id", server.id)
    .eq("name", franchiseName)
    .single();

  if (!franchise) {
    const { data: inserted, error: fErr } = await supabase
      .from("franchises")
      .insert({
        server_id: server.id,
        name: franchiseName,
        discord_franchise_role_id: franchise_role_id,
      })
      .select("*")
      .single();
    if (fErr) return Response.json({ ok: false, error: fErr.message }, { status: 400 });
    franchise = inserted;
  } else if (franchise.discord_franchise_role_id !== franchise_role_id) {
    await supabase
      .from("franchises")
      .update({ discord_franchise_role_id: franchise_role_id })
      .eq("id", franchise.id);
  }

  // Upsert team role ids by abbreviation
  for (const t of team_roles) {
    const code = (t.team_code ?? "").toUpperCase();
    if (!code || !t.role_id) continue;

    // team must already exist (seeded with abbrev). If not, create a skeleton.
    let { data: team } = await supabase
      .from("teams")
      .select("*")
      .eq("franchise_id", franchise.id)
      .eq("abbreviation", code)
      .single();

    if (!team) {
      const { data: inserted, error: tErr } = await supabase
        .from("teams")
        .insert({
          franchise_id: franchise.id,
          name: code,
          abbreviation: code,
          discord_role_id: t.role_id,
        })
        .select("*")
        .single();
      if (tErr) return Response.json({ ok: false, error: tErr.message }, { status: 400 });
      team = inserted;
    } else if (team.discord_role_id !== t.role_id) {
      await supabase
        .from("teams")
        .update({ discord_role_id: t.role_id })
        .eq("id", team.id);
    }
  }

  return Response.json({ ok: true, server_id: server.id, franchise_id: franchise.id });
}

async function handleClaimTeam(payload: any) {
  const { guild_id, franchise_name, team_code, discord_user_id } = payload ?? {};
  if (!guild_id || !franchise_name || !team_code || !discord_user_id) {
    return Response.json({ ok: false, error: "invalid_payload" }, { status: 400 });
  }

  const { data: server } = await supabase
    .from("servers")
    .select("id")
    .eq("discord_guild_id", guild_id)
    .single();

  if (!server) return Response.json({ ok: false, error: "server_not_found" }, { status: 404 });

  const { data: franchise } = await supabase
    .from("franchises")
    .select("id, name")
    .eq("server_id", server.id)
    .eq("name", franchise_name)
    .single();

  if (!franchise) return Response.json({ ok: false, error: "franchise_not_found" }, { status: 404 });

  const code = String(team_code).toUpperCase();
  const { data: team } = await supabase
    .from("teams")
    .select("id, name, abbreviation")
    .eq("franchise_id", franchise.id)
    .eq("abbreviation", code)
    .single();

  if (!team) return Response.json({ ok: false, error: "team_not_found" }, { status: 404 });

  // map discord user to profile
  const { data: profile } = await supabase
    .from("user_profiles")
    .select("id, display_name")
    .eq("discord_id", discord_user_id)
    .single();

  if (!profile) return Response.json({ ok: false, error: "user_not_linked" }, { status: 404 });

  // Assign (make unique per team)
  const { error: upErr } = await supabase
    .from("team_managers")
    .upsert({
      franchise_id: franchise.id,
      team_id: team.id,
      user_id: profile.id,
      discord_id: discord_user_id,
      is_primary: true,
      assigned_at: new Date().toISOString(),
    });
  if (upErr) return Response.json({ ok: false, error: upErr.message }, { status: 400 });

  // Suggested nickname suffix (max nickname length 32, the bot will truncate base name)
  const suffix = `〔${code}·${franchise.name}〕`;
  return Response.json({
    ok: true,
    franchise_id: franchise.id,
    team_id: team.id,
    user_id: profile.id,
    nickname_suffix: suffix,
  });
}

async function handleSetActive(payload: any) {
  const { discord_user_id, guild_id, franchise_name, team_code } = payload ?? {};
  if (!discord_user_id || !guild_id || !franchise_name || !team_code) {
    return Response.json({ ok: false, error: "invalid_payload" }, { status: 400 });
  }

  const { data: server } = await supabase
    .from("servers").select("id").eq("discord_guild_id", guild_id).single();
  if (!server) return Response.json({ ok: false, error: "server_not_found" }, { status: 404 });

  const { data: franchise } = await supabase
    .from("franchises").select("id, name")
    .eq("server_id", server.id).eq("name", franchise_name).single();
  if (!franchise) return Response.json({ ok: false, error: "franchise_not_found" }, { status: 404 });

  const code = String(team_code).toUpperCase();
  const { data: team } = await supabase
    .from("teams").select("id, abbreviation")
    .eq("franchise_id", franchise.id).eq("abbreviation", code).single();
  if (!team) return Response.json({ ok: false, error: "team_not_found" }, { status: 404 });

  const { data: profile } = await supabase
    .from("user_profiles").select("id, display_name").eq("discord_id", discord_user_id).single();
  if (!profile) return Response.json({ ok: false, error: "user_not_linked" }, { status: 404 });

  await supabase
    .from("user_active_context")
    .upsert({
      user_id: profile.id,
      franchise_id: franchise.id,
      team_id: team.id,
      updated_at: new Date().toISOString(),
    });

  const suffix = `〔${code}·${franchise.name}〕`;
  return Response.json({ ok: true, nickname_suffix: suffix });
}

serve(async (req) => {
  const url = new URL(req.url);
  const rawBody = await req.text();

  const authErr = await verify(req, rawBody);
  if (authErr) return authErr;

  const payload = rawBody ? JSON.parse(rawBody) : {};

  if (req.method === "POST" && url.pathname.endsWith("/register_franchise")) {
    return await handleRegisterFranchise(payload);
  }
  if (req.method === "POST" && url.pathname.endsWith("/claim_team")) {
    return await handleClaimTeam(payload);
  }
  if (req.method === "POST" && url.pathname.endsWith("/set_active")) {
    return await handleSetActive(payload);
  }

  return new Response("Not Found", { status: 404 });
});


