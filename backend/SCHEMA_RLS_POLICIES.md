# Secure RLS Policies for DM Tables

This document describes the schema and recommended Row Level Security (RLS) policies for the Direct Message (DM) system in Franchise Player. These policies are designed for maximum security and privacy, ensuring users can only access DMs they participate in.

---

## Schema Context (Relevant Tables)

```
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.dm_channels (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  created_at timestamp with time zone DEFAULT now(),
  livekit_room_id text UNIQUE,
  call_active boolean DEFAULT false,
  CONSTRAINT dm_channels_pkey PRIMARY KEY (id)
);

CREATE TABLE public.dm_participants (
  dm_channel_id uuid NOT NULL,
  user_id uuid NOT NULL,
  joined_at timestamp with time zone DEFAULT now(),
  last_read_message_id uuid,
  CONSTRAINT dm_participants_pkey PRIMARY KEY (dm_channel_id, user_id),
  CONSTRAINT dm_participants_dm_channel_id_fkey FOREIGN KEY (dm_channel_id) REFERENCES public.dm_channels(id),
  CONSTRAINT dm_participants_last_read_message_id_fkey FOREIGN KEY (last_read_message_id) REFERENCES public.messages(id)
);

CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  channel_id uuid,
  dm_channel_id uuid,
  author_id uuid NOT NULL,
  content text,
  edited_at timestamp with time zone,
  is_deleted boolean DEFAULT false,
  deleted_at timestamp with time zone,
  attachments jsonb DEFAULT '[]'::jsonb,
  embeds jsonb DEFAULT '[]'::jsonb,
  reply_to_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES public.channels(id),
  CONSTRAINT messages_dm_channel_id_fkey FOREIGN KEY (dm_channel_id) REFERENCES public.dm_channels(id),
  CONSTRAINT messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.messages(id)
);
```

---

## RLS Policy Recommendations

### 1. `dm_channels` Table

**Enable RLS:**
```sql
ALTER TABLE dm_channels ENABLE ROW LEVEL SECURITY;
```

**Policies:**
```sql
-- SELECT: Only if user is a participant
CREATE POLICY "Select own DM channels"
  ON dm_channels
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM dm_participants
      WHERE dm_participants.dm_channel_id = dm_channels.id
        AND dm_participants.user_id = auth.uid()
    )
  );

-- INSERT: Allow if user will be a participant (enforced by app logic)
CREATE POLICY "Insert DM channel if user is participant"
  ON dm_channels
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
  );
```

**Explanation:**
- Users can only see DM channels they participate in.
- Users can only create a DM channel if authenticated. (App logic should ensure they are added as a participant.)

---

### 2. `dm_participants` Table

**Enable RLS:**
```sql
ALTER TABLE dm_participants ENABLE ROW LEVEL SECURITY;
```

**Policies:**
```sql
-- SELECT: Only see your own participation
CREATE POLICY "Select own DM participations"
  ON dm_participants
  FOR SELECT
  USING (
    user_id = auth.uid()
  );

-- INSERT: Only insert yourself as a participant
CREATE POLICY "Insert self as DM participant"
  ON dm_participants
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
  );
```

**Explanation:**
- Users can only see their own DM participations.
- Users can only add themselves as a participant.

---

### 3. `messages` Table (for DMs)

**Enable RLS:**
```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
```

**Policies:**
```sql
-- SELECT: Only messages in DMs you participate in
CREATE POLICY "Select messages in own DMs"
  ON messages
  FOR SELECT
  USING (
    dm_channel_id IS NULL OR
    EXISTS (
      SELECT 1 FROM dm_participants
      WHERE dm_participants.dm_channel_id = messages.dm_channel_id
        AND dm_participants.user_id = auth.uid()
    )
  );

-- INSERT: Only into DMs you participate in
CREATE POLICY "Insert messages in own DMs"
  ON messages
  FOR INSERT
  WITH CHECK (
    dm_channel_id IS NULL OR
    EXISTS (
      SELECT 1 FROM dm_participants
      WHERE dm_participants.dm_channel_id = messages.dm_channel_id
        AND dm_participants.user_id = auth.uid()
    )
  );
```

**Explanation:**
- Users can only see and insert messages in DMs they participate in.
- Messages for public channels (where `dm_channel_id IS NULL`) are not restricted by these policies.

---

## Notes
- These policies assume your application logic always adds the user as a participant when creating a DM channel.
- You may need to add similar policies for `UPDATE` and `DELETE` if you want users to edit/delete their own messages or DMs.
- Always test your policies in Supabase to ensure they work as intended and do not leak data. 