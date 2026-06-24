-- Run this in Supabase SQL Editor
-- Creates the upsert_conversation RPC function for atomic conversation metadata updates

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
-- Only updates for users whose lastMessageId matches p_message_id
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
-- Delete message + update conversation metadata
-- Handles both "delete for me" and "delete for everyone"
-- Does NOT depend on any Firestore reads — only DB params
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
    -- 1. Mark message as deleted for everyone
    EXECUTE format('UPDATE %I SET deleted_for_everyone = TRUE WHERE id = $1', table_name)
    USING p_deleted_message_id;

    -- 2. Get message sender
    EXECUTE format('SELECT sender_id FROM %I WHERE id = $1', table_name)
    INTO msg_sender
    USING p_deleted_message_id;

    -- 3. Read conversation data
    SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
    IF existing IS NULL THEN RETURN; END IF;

    receiver_unread := COALESCE((existing->p_receiver_id->>'unread')::int, 0);

    -- 4. Update preview only for users where this was the last message
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

    -- 5. If sender is deleting, decrement receiver's unread
    IF msg_sender = p_user_id AND receiver_unread > 0 THEN
      existing := jsonb_set(existing, ARRAY[p_receiver_id, 'unread'], to_jsonb(receiver_unread - 1));
    END IF;

    UPDATE conversations SET last_update_time = now(), user_data = existing WHERE id = p_convo_id;

  ELSE
    -- Delete for me: append user to deleted_for
    EXECUTE format(
      'UPDATE %I SET deleted_for = array_append(COALESCE(deleted_for, ''{}''::text[]), $1) WHERE id = $2',
      table_name
    ) USING p_user_id, p_deleted_message_id;

    -- Check if this was the last message for the user; if not, done
    SELECT user_data INTO existing FROM conversations WHERE id = p_convo_id;
    IF existing IS NULL THEN RETURN; END IF;
    IF existing->p_user_id->>'lastMessageId' != p_deleted_message_id THEN RETURN; END IF;

    -- Find the most recent non-deleted message for this user
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
-- Update conversation preview when a reaction is toggled on
-- the last message (only updates if message is the lastMessage)
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
-- Does NOT depend on any Firestore reads — only DB params
-- ============================================================
CREATE OR REPLACE FUNCTION toggle_message_reaction(
  p_convo_id TEXT,
  p_message_id TEXT,
  p_user_id TEXT,
  p_emoji TEXT,
  p_receiver_id TEXT
) RETURNS void
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

  -- Only update preview if this is the receiver's last message
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
END;
$$;

-- ============================================================
-- Atomically insert message + upsert conversation metadata
-- Bypasses PostgREST schema cache issue for first-time tables,
-- and ensures message + conversation are always consistent
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
  -- 1. Create message table if needed
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

  -- 2. Upsert the message
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

  -- 3. Upsert conversation metadata (same logic as upsert_conversation)
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
-- Update in_timeline flag on a message (add or remove from timeline)
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
