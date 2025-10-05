create table if not exists public.valuation_settings (
  id uuid primary key default gen_random_uuid(),
  server_id uuid references public.servers(id) on delete cascade,
  franchise_id uuid references public.franchises(id) on delete cascade,
  label text default 'default',
  settings jsonb not null,
  updated_at timestamptz default now()
);

-- Add unique constraint separately
alter table public.valuation_settings 
add constraint valuation_settings_unique_franchise_label 
unique (franchise_id, label);

-- Seed one global default row if empty
insert into public.valuation_settings (label, settings)
select 'default', '{
  "pos_spread_scalar": 1.5,
  "pos_offsets": {
    "QB":1.00, "WR":0.55, "CB":0.50, "LT":0.50, "RT":0.50,
    "LE":0.60, "RE":0.60, "LOLB":0.60, "ROLB":0.60,
    "DT":0.40, "FS":0.45, "SS":0.45, "TE":0.40,
    "LG":0.35, "C":0.35, "RG":0.35, "HB":0.35, "MLB":0.30,
    "FB":0.20, "K":0.15, "P":0.10, "LS":0.00
  },

  "ovr_curve": { "qb60": 2.5, "qb99": 6000, "gamma": 1.15 },

  "age": {
    "base_schedule": { "20":2.00,"21":2.00,"22":1.90,"23":1.80,"24":1.70,"25":1.60,"26":1.50,"27":1.40,"28":1.00,"29":1.00,"30":0.95,"31":0.90,"32":0.85,"33":0.80,"34":0.75,"35":0.70,"36":0.65,"37":0.60,"38":0.55,"39":0.50,"40":0.45 },
    "cliff_25_27": 0.90,
    "cliff_28_plus": 0.75,
    "gain": 4.0,
    "post29_decay_enabled": true,
    "post29_start_age": 29,
    "post29_decay_ratio": 0.82,
    "penalty_relief_over28": 0.15,
    "floor_age": 40,
    "floor_value": 0.0
  },

  "youth_buffer": {
    "band": { "20":1.00,"21":1.00,"22":0.85,"23":0.70,"24":0.50,"25":0.35,"26":0.20,"27":0.10,"28":0.00 },
    "dmax": {
      "QB":0.20, "WR":0.14, "CB":0.14, "LE":0.14, "RE":0.14, "LOLB":0.14, "ROLB":0.14,
      "LT":0.10, "RT":0.10, "DT":0.10, "FS":0.10, "SS":0.10, "TE":0.10,
      "MLB":0.08, "HB":0.08, "LG":0.06, "C":0.06, "RG":0.06, "K":0.03, "P":0.02, "LS":0.00
    }
  },

  "dev_trait": {
    "trait_scores": { "Normal":0.00, "Star":2.64, "Superstar":5.36, "X-Factor":8.00 },
    "dcap": {
      "QB":0.20, "WR":0.14, "CB":0.14, "LE":0.14, "RE":0.14, "LOLB":0.14, "ROLB":0.14,
      "LT":0.10, "RT":0.10, "DT":0.10, "FS":0.10, "SS":0.10, "TE":0.10,
      "MLB":0.08, "HB":0.08, "IOL":0.06, "LG":0.06, "C":0.06, "RG":0.06, "K":0.03, "P":0.02, "LS":0.00
    },
    "weights": {
      "QB": {"w_xp":0.50,"w_abil":0.50},
      "WR": {"w_xp":0.50,"w_abil":0.50},
      "CB": {"w_xp":0.50,"w_abil":0.50},
      "LE": {"w_xp":0.50,"w_abil":0.50},
      "RE": {"w_xp":0.50,"w_abil":0.50},
      "LOLB": {"w_xp":0.50,"w_abil":0.50},
      "ROLB": {"w_xp":0.50,"w_abil":0.50},
      "LT": {"w_xp":0.65,"w_abil":0.35},
      "RT": {"w_xp":0.65,"w_abil":0.35},
      "DT": {"w_xp":0.65,"w_abil":0.35},
      "FS": {"w_xp":0.65,"w_abil":0.35},
      "SS": {"w_xp":0.65,"w_abil":0.35},
      "TE": {"w_xp":0.65,"w_abil":0.35},
      "MLB": {"w_xp":0.70,"w_abil":0.30},
      "HB": {"w_xp":0.70,"w_abil":0.30},
      "IOL": {"w_xp":0.80,"w_abil":0.20},
      "LG": {"w_xp":0.80,"w_abil":0.20},
      "C":  {"w_xp":0.80,"w_abil":0.20},
      "RG": {"w_xp":0.80,"w_abil":0.20},
      "K":  {"w_xp":0.90,"w_abil":0.10},
      "P":  {"w_xp":0.90,"w_abil":0.10},
      "LS": {"w_xp":1.00,"w_abil":0.00}
      }
    },

    "gravity": { "enabled": true, "threshold": 6000, "vmax": 18000 },

    "future_picks": {
      "enabled": true,
      "baseline": "mid_round",
      "mid_round_picks": { "1":16, "2":48, "3":80, "4":112, "5":144, "6":176, "7":208 },
      "schedule": {
        "1": { "1": 0.75, "2": 0.50 },
        "2": { "1": 0.80, "2": 0.60 },
        "3": { "1": 0.85, "2": 0.70 },
        "4": { "1": 0.90, "2": 0.80 },
        "5": { "1": 0.90, "2": 0.80 },
        "6": { "1": 0.95, "2": 0.90 },
        "7": { "1": 0.95, "2": 0.90 }
      }
    }
  }'::jsonb
where not exists (select 1 from public.valuation_settings);
