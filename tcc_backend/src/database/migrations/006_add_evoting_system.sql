-- Migration: Add E-Voting System
-- Description: Creates tables for elections/polls, options, and votes

-- Create elections table
CREATE TABLE IF NOT EXISTS elections (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    question TEXT NOT NULL,
    voting_charge DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, ended, paused
    created_by INTEGER REFERENCES admins(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    total_votes INTEGER DEFAULT 0,
    total_revenue DECIMAL(12, 2) DEFAULT 0.00
);

-- Create election_options table
CREATE TABLE IF NOT EXISTS election_options (
    id SERIAL PRIMARY KEY,
    election_id INTEGER NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    vote_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create election_votes table
CREATE TABLE IF NOT EXISTS election_votes (
    id SERIAL PRIMARY KEY,
    election_id INTEGER NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
    option_id INTEGER NOT NULL REFERENCES election_options(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id),
    vote_charge DECIMAL(10, 2) NOT NULL,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(election_id, user_id) -- One vote per user per election
);

-- Create indexes for better query performance
CREATE INDEX idx_elections_status ON elections(status);
CREATE INDEX idx_elections_end_time ON elections(end_time);
CREATE INDEX idx_election_votes_user ON election_votes(user_id);
CREATE INDEX idx_election_votes_election ON election_votes(election_id);
CREATE INDEX idx_election_options_election ON election_options(election_id);

-- Create trigger to update election stats when vote is cast
CREATE OR REPLACE FUNCTION update_election_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update option vote count
    UPDATE election_options
    SET vote_count = vote_count + 1
    WHERE id = NEW.option_id;

    -- Update election total votes and revenue
    UPDATE elections
    SET total_votes = total_votes + 1,
        total_revenue = total_revenue + NEW.vote_charge
    WHERE id = NEW.election_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_election_stats
AFTER INSERT ON election_votes
FOR EACH ROW
EXECUTE FUNCTION update_election_stats();

-- Create function to automatically end elections
CREATE OR REPLACE FUNCTION auto_end_elections()
RETURNS void AS $$
BEGIN
    UPDATE elections
    SET status = 'ended',
        ended_at = CURRENT_TIMESTAMP
    WHERE status = 'active'
    AND end_time <= CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE elections IS 'Stores election/poll information';
COMMENT ON TABLE election_options IS 'Stores options for each election';
COMMENT ON TABLE election_votes IS 'Stores user votes for elections';
COMMENT ON COLUMN elections.voting_charge IS 'Cost in TCC coins to cast a vote';
COMMENT ON COLUMN elections.status IS 'Election status: active, ended, paused';
