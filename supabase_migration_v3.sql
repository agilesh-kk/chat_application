-- Run this in Supabase SQL Editor
-- Migration v3: Message sending via Supabase RPCs
-- Moves message writes from Firestore to Supabase while keeping Firestore for reads/listeners

-- ============================================================
-- Create conversations table
-- ============================================================
CREATE TABLE IF NOT EXISTS conversations (
  id TEXT PRIMARY KEY,
  participants_id TEXT[] NOT NULL,
  last_update_time TIMESTAMPTZ DEFAULT now(),
  user_data JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_conversations_participants
  ON conversations USING GIN (participants_id);

-- ============================================================
-- Upsert conversation metadata (used internally and on first message)
-- ============================================================
CREATE OR REPLACE FUNCTION upsert_conversation(
  p_convo_id TEXT,
  p_participants_id TEXT[],
  p_user_id TEXT,
  p_receiver_id TEXT,
  p_last_message TEXT,
  p_last_message_id TEXT,
  p_last_sender TEXT,
  p_is_friend BOOLEAN DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing JSONB;
BEGIN
  SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;

  IF existing IS NULL THEN
    INSERT INTO conversations (id, participants_id, last_update_time, user_data)
    VALUES (
      p_convo_id, p_participants_id, now(),
      jsonb_build_object(
        p_user_id, jsonb_build_object(
          'receiverId', p_receiver_id, 'unread', 0,
          'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
          'lastSender', p_last_sender, 'lastupdateTime', now(), 'isFriend', p_is_friend
        ),
        p_receiver_id, jsonb_build_object(
          'receiverId', p_user_id, 'unread', 1,
          'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
          'lastSender', p_last_sender, 'lastupdateTime', now(), 'isFriend', p_is_friend
        )
      )
    );
  ELSE
    UPDATE conversations SET
      last_update_time = now(),
      user_data = existing
        || jsonb_build_object(p_user_id,
             COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object(
               'receiverId', p_receiver_id, 'unread', 0,
               'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
               'lastSender', p_last_sender, 'lastupdateTime', now()
             ))
        || jsonb_build_object(p_receiver_id,
             COALESCE(existing->p_receiver_id, '{}'::jsonb) || jsonb_build_object(
               'receiverId', p_user_id,
               'unread', COALESCE((existing->p_receiver_id->>'unread')::int, 0) + 1,
               'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
               'lastSender', p_last_sender, 'lastupdateTime', now()
             ))
    WHERE id = p_convo_id;
  END IF;
END;
$$;

-- ============================================================
-- Reset unread count for a user in a conversation
-- ============================================================
CREATE OR REPLACE FUNCTION reset_unread(p_convo_id TEXT, p_user_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE conversations SET
    user_data = jsonb_set(
      COALESCE(user_data, '{}'::jsonb),
      ARRAY[p_user_id, 'unread'],
      '0'
    )
  WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Edit the last message preview in conversation metadata
-- ============================================================
CREATE OR REPLACE FUNCTION edit_conversation_last_message(
  p_convo_id TEXT,
  p_user_id TEXT,
  p_receiver_id TEXT,
  p_message_id TEXT,
  p_new_content TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing JSONB;
BEGIN
  SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
  IF existing IS NULL THEN RETURN; END IF;

  IF existing->p_user_id->>'lastMessageId' = p_message_id THEN
    existing := existing || jsonb_build_object(p_user_id,
      COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object('lastMessage', p_new_content));
  END IF;

  IF existing->p_receiver_id->>'lastMessageId' = p_message_id THEN
    existing := existing || jsonb_build_object(p_receiver_id,
      COALESCE(existing->p_receiver_id, '{}'::jsonb) || jsonb_build_object('lastMessage', p_new_content));
  END IF;

  UPDATE conversations SET last_update_time = now(), user_data = existing WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Fetch all messages for a conversation from the sharded table
-- ============================================================
CREATE OR REPLACE FUNCTION fetch_conversation_messages(p_convo_id TEXT)
RETURNS JSONB[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  msg_table TEXT;
  result JSONB[];
  msg_record RECORD;
BEGIN
  msg_table := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  -- Check if table exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = msg_table
  ) THEN
    FOR msg_record IN
      EXECUTE format(
        'SELECT id, sender_id, content, type, status, is_edited, reactions,
                created_at, reply_to_id, reply_to_content, reply_to_sender_id,
                reply_to_type, deleted_for, deleted_for_everyone, name,
                profile, is_scheduled, send_at,
                receiver_id
         FROM %I ORDER BY created_at DESC',
        msg_table
      )
    LOOP
      result := array_append(result, jsonb_build_object(
        'id', msg_record.id,
        'sender_id', msg_record.sender_id,
        'content', msg_record.content,
        'type', msg_record.type,
        'status', msg_record.status,
        'is_edited', msg_record.is_edited,
        'reactions', msg_record.reactions,
        'created_at', extract(epoch from msg_record.created_at)::bigint * 1000,
        'reply_to_id', msg_record.reply_to_id,
        'reply_to_content', msg_record.reply_to_content,
        'reply_to_sender_id', msg_record.reply_to_sender_id,
        'reply_to_type', msg_record.reply_to_type,
        'deleted_for', COALESCE(msg_record.deleted_for, '{}'),
        'deleted_for_everyone', msg_record.deleted_for_everyone,
        'name', msg_record.name,
        'convo_id', p_convo_id,
        'profile', msg_record.profile,
        'is_scheduled', msg_record.is_scheduled,
        'send_at', extract(epoch from msg_record.send_at)::bigint * 1000,
        'receiver_id', msg_record.receiver_id
      ));
    END LOOP;
  END IF;

  RETURN COALESCE(result, ARRAY[]::JSONB[]);
END;
$$;

-- ============================================================
-- Get IDs of sent-but-unseen messages from a sender
-- ============================================================
CREATE OR REPLACE FUNCTION get_sent_unseen_message_ids(
  p_convo_id TEXT,
  p_sender_id TEXT,
  p_receiver_id TEXT
)
RETURNS TEXT[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  msg_table TEXT;
  result TEXT[];
BEGIN
  msg_table := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  IF EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = msg_table
  ) THEN
    EXECUTE format(
      'SELECT array_agg(id) FROM %I WHERE sender_id = $1 AND status = ''sent''',
      msg_table
    ) INTO result USING p_sender_id;
  END IF;

  RETURN COALESCE(result, ARRAY[]::TEXT[]);
END;
$$;

-- ============================================================
-- Delete message + update conversation metadata
-- ============================================================
CREATE OR REPLACE FUNCTION delete_message_and_update_conversation(
  p_convo_id TEXT,
  p_user_id TEXT,
  p_receiver_id TEXT,
  p_deleted_message_id TEXT,
  p_delete_for_everyone BOOLEAN DEFAULT false
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  table_name TEXT;
  existing JSONB;
  msg_sender TEXT;
  new_last_id TEXT;
  new_last_content TEXT;
  new_last_sender TEXT;
  new_last_time TIMESTAMPTZ;
  new_last_type TEXT;
  receiver_unread INT;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  IF p_delete_for_everyone THEN
    EXECUTE format('UPDATE %I SET deleted_for_everyone = TRUE WHERE id = $1', table_name)
    USING p_deleted_message_id;

    EXECUTE format('SELECT sender_id FROM %I WHERE id = $1', table_name)
    INTO msg_sender
    USING p_deleted_message_id;

    SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
    IF existing IS NULL THEN RETURN; END IF;

    receiver_unread := COALESCE((existing->p_receiver_id->>'unread')::int, 0);

    IF existing->p_user_id->>'lastMessageId' = p_deleted_message_id THEN
      existing := existing || jsonb_build_object(p_user_id,
        COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object(
          'lastMessage', 'This message was deleted',
          'lastSender', msg_sender
        ));
    END IF;

    IF existing->p_receiver_id->>'lastMessageId' = p_deleted_message_id THEN
      existing := existing || jsonb_build_object(p_receiver_id,
        COALESCE(existing->p_receiver_id, '{}'::jsonb) || jsonb_build_object(
          'lastMessage', 'This message was deleted',
          'lastSender', msg_sender
        ));
    END IF;

    IF msg_sender = p_user_id AND receiver_unread > 0 THEN
      existing := jsonb_set(existing, ARRAY[p_receiver_id, 'unread'], to_jsonb(receiver_unread - 1));
    END IF;

    UPDATE conversations SET last_update_time = now(), user_data = existing WHERE id = p_convo_id;

  ELSE
    EXECUTE format(
      'UPDATE %I SET deleted_for = array_append(COALESCE(deleted_for, ''{}''::text[]), $1) WHERE id = $2',
      table_name
    ) USING p_user_id, p_deleted_message_id;

    SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
    IF existing IS NULL THEN RETURN; END IF;
    IF existing->p_user_id->>'lastMessageId' != p_deleted_message_id THEN RETURN; END IF;

    EXECUTE format(
      'SELECT id, content, sender_id, created_at, type FROM %I
       WHERE id != $1
         AND (deleted_for IS NULL OR NOT ($2 = ANY(deleted_for)))
         AND deleted_for_everyone = FALSE
       ORDER BY created_at DESC LIMIT 1',
      table_name
    ) INTO new_last_id, new_last_content, new_last_sender, new_last_time, new_last_type
    USING p_deleted_message_id, p_user_id;

    IF new_last_id IS NOT NULL THEN
      existing := existing || jsonb_build_object(p_user_id,
        COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object(
          'lastMessage', CASE WHEN COALESCE(new_last_type, 'text') = 'text' THEN COALESCE(new_last_content, '') ELSE '📷 Image' END,
          'lastMessageId', new_last_id,
          'lastSender', new_last_sender,
          'lastupdateTime', new_last_time
        ));
    ELSE
      existing := existing || jsonb_build_object(p_user_id,
        COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object(
          'lastMessage', '',
          'lastMessageId', '',
          'lastSender', '',
          'lastupdateTime', now()
        ));
    END IF;

    UPDATE conversations SET last_update_time = now(), user_data = existing WHERE id = p_convo_id;
  END IF;
END;
$$;

-- ============================================================
-- Update conversation preview when a reaction is toggled on the last message
-- ============================================================
CREATE OR REPLACE FUNCTION update_reaction_preview(
  p_convo_id TEXT,
  p_target_user TEXT,
  p_preview TEXT,
  p_sender_id TEXT,
  p_message_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_convo_id AND user_data->p_target_user->>'lastMessageId' = p_message_id
  ) THEN
    UPDATE conversations SET
      user_data = COALESCE(user_data, '{}'::jsonb)
        || jsonb_build_object(p_target_user,
             COALESCE(user_data->p_target_user, '{}'::jsonb) || jsonb_build_object(
               'lastMessage', p_preview,
               'lastSender', p_sender_id
             ))
    WHERE id = p_convo_id;
  END IF;
END;
$$;

-- ============================================================
-- Mark all sent messages from receiver as seen, reset unread
-- ============================================================
CREATE OR REPLACE FUNCTION mark_messages_seen(
  p_convo_id TEXT,
  p_user_id TEXT,
  p_receiver_id TEXT
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  table_name TEXT;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  EXECUTE format('UPDATE %I SET status = ''seen'' WHERE sender_id = $1 AND status = ''sent''', table_name)
  USING p_receiver_id;

  UPDATE conversations SET
    user_data = jsonb_set(COALESCE(user_data, '{}'::jsonb), ARRAY[p_user_id, 'unread'], '0')
  WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Toggle a reaction on a message + update conversation preview
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_message_reaction(
  p_convo_id TEXT,
  p_message_id TEXT,
  p_user_id TEXT,
  p_emoji TEXT,
  p_receiver_id TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  table_name TEXT;
  current_reactions JSONB;
  current_emoji TEXT;
  msg_content TEXT;
  msg_sender TEXT;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  EXECUTE format('SELECT reactions, content, sender_id FROM %I WHERE id = $1', table_name)
  INTO current_reactions, msg_content, msg_sender
  USING p_message_id;

  IF current_reactions IS NULL THEN
    current_reactions := '{}'::jsonb;
  END IF;

  current_emoji := current_reactions->>p_user_id;

  IF current_emoji = p_emoji THEN
    current_reactions := current_reactions - p_user_id;
  ELSE
    current_reactions := jsonb_set(COALESCE(current_reactions, '{}'::jsonb), ARRAY[p_user_id], to_jsonb(p_emoji));
  END IF;

  EXECUTE format('UPDATE %I SET reactions = $1 WHERE id = $2', table_name)
  USING current_reactions, p_message_id;

  IF EXISTS (
    SELECT 1 FROM conversations
    WHERE id = p_convo_id AND user_data->p_receiver_id->>'lastMessageId' = p_message_id
  ) THEN
    IF current_emoji = p_emoji THEN
      UPDATE conversations SET
        user_data = COALESCE(user_data, '{}'::jsonb)
          || jsonb_build_object(p_receiver_id,
               COALESCE(user_data->p_receiver_id, '{}'::jsonb) || jsonb_build_object(
                 'lastMessage', COALESCE(msg_content, '📷 Image'),
                 'lastSender', msg_sender
               ))
      WHERE id = p_convo_id;
    ELSE
      UPDATE conversations SET
        user_data = COALESCE(user_data, '{}'::jsonb)
          || jsonb_build_object(p_receiver_id,
               COALESCE(user_data->p_receiver_id, '{}'::jsonb) || jsonb_build_object(
                 'lastMessage', 'Reacted ' || p_emoji || ' to a message',
                 'lastSender', p_user_id
               ))
      WHERE id = p_convo_id;
    END IF;
  END IF;

  RETURN current_reactions;
END;
$$;

-- ============================================================
-- Atomically insert message + upsert conversation metadata
-- ============================================================
CREATE OR REPLACE FUNCTION send_message_and_update_conversation(
  p_convo_id TEXT,
  p_participants_id TEXT[],
  p_user_id TEXT,
  p_receiver_id TEXT,
  p_last_message TEXT,
  p_last_message_id TEXT,
  p_last_sender TEXT,
  p_id TEXT,
  p_sender_id TEXT,
  p_is_friend BOOLEAN DEFAULT true,
  p_content TEXT DEFAULT NULL,
  p_type TEXT DEFAULT 'text',
  p_status TEXT DEFAULT 'sent',
  p_created_at TIMESTAMPTZ DEFAULT now(),
  p_deleted_for TEXT[] DEFAULT '{}',
  p_deleted_for_everyone BOOLEAN DEFAULT false,
  p_is_edited BOOLEAN DEFAULT false,
  p_reactions JSONB DEFAULT '{}',
  p_reply_to_id TEXT DEFAULT NULL,
  p_reply_to_content TEXT DEFAULT NULL,
  p_reply_to_sender_id TEXT DEFAULT NULL,
  p_reply_to_type TEXT DEFAULT NULL,
  p_is_scheduled BOOLEAN DEFAULT false,
  p_send_at TIMESTAMPTZ DEFAULT NULL,
  p_in_timeline BOOLEAN DEFAULT false,
  p_name TEXT DEFAULT NULL,
  p_profile TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  table_name TEXT;
  existing JSONB;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS %I (
      id TEXT PRIMARY KEY,
      sender_id TEXT NOT NULL,
      content TEXT,
      type TEXT DEFAULT %L,
      status TEXT DEFAULT %L,
      created_at TIMESTAMPTZ,
      deleted_for TEXT[] DEFAULT %L,
      deleted_for_everyone BOOLEAN DEFAULT FALSE,
      is_edited BOOLEAN DEFAULT FALSE,
      reactions JSONB DEFAULT %L,
      reply_to_id TEXT,
      reply_to_content TEXT,
      reply_to_sender_id TEXT,
      reply_to_type TEXT,
      is_scheduled BOOLEAN DEFAULT FALSE,
      send_at TIMESTAMPTZ,
      in_timeline BOOLEAN DEFAULT FALSE,
      name TEXT,
      receiver_id TEXT,
      profile TEXT
    )',
    table_name, 'text', 'sent', '{}', '{}'
  );

  EXECUTE format(
    'INSERT INTO %I (id, sender_id, content, type, status, created_at,
      deleted_for, deleted_for_everyone, is_edited, reactions,
      reply_to_id, reply_to_content, reply_to_sender_id, reply_to_type,
      is_scheduled, send_at, in_timeline, name, receiver_id, profile)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
             $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
     ON CONFLICT (id) DO UPDATE SET
       content = EXCLUDED.content,
       type = EXCLUDED.type,
       status = EXCLUDED.status,
       is_edited = EXCLUDED.is_edited,
       reactions = EXCLUDED.reactions,
       deleted_for = EXCLUDED.deleted_for,
       deleted_for_everyone = EXCLUDED.deleted_for_everyone',
    table_name
  )
  USING
    p_id, p_sender_id, p_content, p_type, p_status, p_created_at,
    p_deleted_for, p_deleted_for_everyone, p_is_edited, p_reactions,
    p_reply_to_id, p_reply_to_content, p_reply_to_sender_id, p_reply_to_type,
    p_is_scheduled, p_send_at, p_in_timeline, p_name, p_receiver_id, p_profile;

  SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;

  IF existing IS NULL THEN
    INSERT INTO conversations (id, participants_id, last_update_time, user_data)
    VALUES (
      p_convo_id, p_participants_id, now(),
      jsonb_build_object(
        p_user_id, jsonb_build_object(
          'receiverId', p_receiver_id, 'unread', 0,
          'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
          'lastSender', p_last_sender, 'lastupdateTime', now(), 'isFriend', p_is_friend
        ),
        p_receiver_id, jsonb_build_object(
          'receiverId', p_user_id, 'unread', 1,
          'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
          'lastSender', p_last_sender, 'lastupdateTime', now(), 'isFriend', p_is_friend
        )
      )
    );
  ELSE
    UPDATE conversations SET
      last_update_time = now(),
      user_data = existing
        || jsonb_build_object(p_user_id,
             COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object(
               'receiverId', p_receiver_id, 'unread', 0,
               'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
               'lastSender', p_last_sender, 'lastupdateTime', now()
             ))
        || jsonb_build_object(p_receiver_id,
             COALESCE(existing->p_receiver_id, '{}'::jsonb) || jsonb_build_object(
               'receiverId', p_user_id,
               'unread', COALESCE((existing->p_receiver_id->>'unread')::int, 0) + 1,
               'lastMessage', p_last_message, 'lastMessageId', p_last_message_id,
               'lastSender', p_last_sender, 'lastupdateTime', now()
             ))
    WHERE id = p_convo_id;
  END IF;
END;
$$;

-- ============================================================
-- Update in_timeline flag on a message
-- ============================================================
CREATE OR REPLACE FUNCTION update_message_timeline(
  p_convo_id TEXT,
  p_message_id TEXT,
  p_in_timeline BOOLEAN
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE table_name TEXT;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);
  EXECUTE format('UPDATE %I SET in_timeline = $1 WHERE id = $2', table_name)
  USING p_in_timeline, p_message_id;
END;
$$;

-- ============================================================
-- Update isFriend flag for both users in conversation metadata
-- ============================================================
CREATE OR REPLACE FUNCTION update_conversation_friend_status(
  p_convo_id TEXT,
  p_user_id TEXT,
  p_friend_id TEXT,
  p_is_friend BOOLEAN
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  existing JSONB;
BEGIN
  SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
  IF existing IS NULL THEN RETURN; END IF;

  UPDATE conversations SET
    user_data = existing
      || jsonb_build_object(p_user_id,
           COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object('isFriend', p_is_friend))
      || jsonb_build_object(p_friend_id,
           COALESCE(existing->p_friend_id, '{}'::jsonb) || jsonb_build_object('isFriend', p_is_friend))
  WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Enable realtime on conversations table
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
  END IF;
END;
$$;

-- ============================================================
-- One-time migration: insert a Firestore conversation row
-- Called from Dart after reading Firestore
-- ============================================================
CREATE OR REPLACE FUNCTION migrate_conversation(
  p_id TEXT,
  p_participants_id TEXT[],
  p_last_update_time TIMESTAMPTZ,
  p_user_data JSONB
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO conversations (id, participants_id, last_update_time, user_data)
  VALUES (p_id, p_participants_id, p_last_update_time, p_user_data)
  ON CONFLICT (id) DO NOTHING;
END;
$$;

-- ============================================================
-- One-time migration: insert a single message into its sharded table
-- Called from Dart migration script
-- ============================================================
CREATE OR REPLACE FUNCTION migrate_message(
  p_convo_id TEXT,
  p_id TEXT,
  p_sender_id TEXT,
  p_content TEXT,
  p_type TEXT DEFAULT 'text',
  p_status TEXT DEFAULT 'sent',
  p_created_at BIGINT DEFAULT 0,
  p_deleted_for TEXT[] DEFAULT '{}',
  p_deleted_for_everyone BOOLEAN DEFAULT false,
  p_is_edited BOOLEAN DEFAULT false,
  p_reactions JSONB DEFAULT '{}',
  p_reply_to_id TEXT DEFAULT NULL,
  p_reply_to_content TEXT DEFAULT NULL,
  p_reply_to_sender_id TEXT DEFAULT NULL,
  p_reply_to_type TEXT DEFAULT NULL,
  p_is_scheduled BOOLEAN DEFAULT false,
  p_send_at BIGINT DEFAULT NULL,
  p_in_timeline BOOLEAN DEFAULT false,
  p_name TEXT DEFAULT NULL,
  p_receiver_id TEXT DEFAULT NULL,
  p_profile TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  table_name TEXT;
BEGIN
  table_name := 'msg_' || substring(md5(p_convo_id) from 1 for 16);

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS %I (
      id TEXT PRIMARY KEY,
      sender_id TEXT NOT NULL,
      content TEXT,
      type TEXT DEFAULT ''text'',
      status TEXT DEFAULT ''sent'',
      created_at TIMESTAMPTZ,
      deleted_for TEXT[] DEFAULT ''{}'',
      deleted_for_everyone BOOLEAN DEFAULT FALSE,
      is_edited BOOLEAN DEFAULT FALSE,
      reactions JSONB DEFAULT ''{}'',
      reply_to_id TEXT,
      reply_to_content TEXT,
      reply_to_sender_id TEXT,
      reply_to_type TEXT,
      is_scheduled BOOLEAN DEFAULT FALSE,
      send_at TIMESTAMPTZ,
      in_timeline BOOLEAN DEFAULT FALSE,
      name TEXT,
      receiver_id TEXT,
      profile TEXT
    )',
    table_name
  );

  EXECUTE format(
    'INSERT INTO %I (id, sender_id, content, type, status, created_at,
      deleted_for, deleted_for_everyone, is_edited, reactions,
      reply_to_id, reply_to_content, reply_to_sender_id, reply_to_type,
      is_scheduled, send_at, in_timeline, name, receiver_id, profile)
     VALUES ($1, $2, $3, $4, $5, to_timestamp($6::double precision / 1000),
             $7, $8, $9, $10, $11, $12, $13, $14, $15,
             CASE WHEN $16 IS NOT NULL THEN to_timestamp($16::double precision / 1000) ELSE NULL END,
             $17, $18, $19, $20)
     ON CONFLICT (id) DO NOTHING',
    table_name
  )
  USING
    p_id, p_sender_id, p_content, p_type, p_status, p_created_at,
    p_deleted_for, p_deleted_for_everyone, p_is_edited, p_reactions,
    p_reply_to_id, p_reply_to_content, p_reply_to_sender_id, p_reply_to_type,
    p_is_scheduled, p_send_at, p_in_timeline, p_name, p_receiver_id, p_profile;
END;
$$;

-- ============================================================
-- Fetch conversations for a user (server-filtered + ordered)
-- ============================================================
CREATE OR REPLACE FUNCTION get_conversations_for_user(p_user_id TEXT)
RETURNS JSONB[]
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  result JSONB[];
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT * FROM conversations
    WHERE p_user_id = ANY(participants_id)
    ORDER BY last_update_time DESC
  LOOP
    result := array_append(result, jsonb_build_object(
      'id', rec.id,
      'participants_id', rec.participants_id,
      'last_update_time', extract(epoch from rec.last_update_time)::bigint * 1000,
      'user_data', rec.user_data
    ));
  END LOOP;
  RETURN COALESCE(result, ARRAY[]::JSONB[]);
END;
$$;
