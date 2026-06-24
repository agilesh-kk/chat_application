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
-- (used when the edited message is the current lastMessage)
-- ============================================================
CREATE OR REPLACE FUNCTION edit_conversation_last_message(
  p_convo_id TEXT,
  p_user_id TEXT,
  p_receiver_id TEXT,
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

  UPDATE conversations SET
    last_update_time = now(),
    user_data = existing
      || jsonb_build_object(p_user_id,
           COALESCE(existing->p_user_id, '{}'::jsonb) || jsonb_build_object('lastMessage', p_new_content))
      || jsonb_build_object(p_receiver_id,
           COALESCE(existing->p_receiver_id, '{}'::jsonb) || jsonb_build_object('lastMessage', p_new_content))
  WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Delete / replace last message in conversation metadata
-- Handles both "delete for me" and "delete for everyone"
-- ============================================================
CREATE OR REPLACE FUNCTION delete_conversation_last_message(
  p_convo_id TEXT,
  p_target_user TEXT,
  p_last_message TEXT DEFAULT '',
  p_last_message_id TEXT DEFAULT '',
  p_last_sender TEXT DEFAULT '',
  p_last_update_time TIMESTAMPTZ DEFAULT now(),
  -- Delete-for-everyone: also update the other user's fields
  p_other_user TEXT DEFAULT NULL,
  p_other_last_message TEXT DEFAULT NULL,
  p_other_last_sender TEXT DEFAULT NULL,
  -- Negative delta when decrementing unread (delete-for-everyone)
  p_unread_delta INT DEFAULT 0
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

  UPDATE conversations SET
    last_update_time = now(),
    user_data = existing
      || jsonb_build_object(p_target_user,
           COALESCE(existing->p_target_user, '{}'::jsonb) || jsonb_build_object(
             'lastMessage', p_last_message,
             'lastMessageId', p_last_message_id,
             'lastSender', p_last_sender,
             'lastupdateTime', p_last_update_time
           ))
      || CASE WHEN p_other_user IS NOT NULL THEN
           jsonb_build_object(p_other_user,
             COALESCE(existing->p_other_user, '{}'::jsonb) || jsonb_build_object(
               'lastMessage', COALESCE(p_other_last_message, p_last_message),
               'lastSender', COALESCE(p_other_last_sender, p_last_sender),
               'unread', GREATEST(COALESCE((existing->p_other_user->>'unread')::int, 0) + p_unread_delta, 0)
             ))
         ELSE
           '{}'::jsonb
         END
  WHERE id = p_convo_id;
END;
$$;

-- ============================================================
-- Update conversation preview when a reaction is toggled on
-- the last message
-- ============================================================
CREATE OR REPLACE FUNCTION update_reaction_preview(
  p_convo_id TEXT,
  p_target_user TEXT,
  p_preview TEXT,
  p_sender_id TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE conversations SET
    user_data = COALESCE(user_data, '{}'::jsonb)
      || jsonb_build_object(p_target_user,
           COALESCE(user_data->p_target_user, '{}'::jsonb) || jsonb_build_object(
             'lastMessage', p_preview,
             'lastSender', p_sender_id
           ))
  WHERE id = p_convo_id;
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
