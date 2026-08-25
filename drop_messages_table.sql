-- Drop Messages Table Migration Rollback
-- This script removes the messages table and related objects
-- Use this to rollback the messages table creation

-- Drop indexes
DROP INDEX IF EXISTS ix_messages_created_at;
DROP INDEX IF EXISTS ix_messages_sender_role;
DROP INDEX IF EXISTS ix_messages_id;

-- Drop table
DROP TABLE IF EXISTS messages;

-- Drop enum type
DROP TYPE IF EXISTS senderrole;

-- Verify table was dropped
SELECT 'Messages table dropped successfully!' as status;
