-- Rollback Migration: Remove E-Voting System
-- Description: Drops all e-voting related tables and functions

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_update_election_stats ON election_votes;

-- Drop functions
DROP FUNCTION IF EXISTS update_election_stats();
DROP FUNCTION IF EXISTS auto_end_elections();

-- Drop indexes
DROP INDEX IF EXISTS idx_elections_status;
DROP INDEX IF EXISTS idx_elections_end_time;
DROP INDEX IF EXISTS idx_election_votes_user;
DROP INDEX IF EXISTS idx_election_votes_election;
DROP INDEX IF EXISTS idx_election_options_election;

-- Drop tables (in reverse order of dependencies)
DROP TABLE IF EXISTS election_votes;
DROP TABLE IF EXISTS election_options;
DROP TABLE IF EXISTS elections;
