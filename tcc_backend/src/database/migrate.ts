import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import config from '../config';

const pool = new Pool({
  host: config.database.host,
  port: config.database.port,
  database: config.database.name,
  user: config.database.user,
  password: config.database.password,
  ssl: config.database.ssl
    ? {
        rejectUnauthorized: false,
      }
    : false,
});

async function runMigrations() {
  const migrationsDir = path.join(__dirname, 'migrations');

  try {
    console.log('Starting database migrations...');

    // Create migrations table if it doesn't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        migration_name VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Get list of migration files
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    console.log(`Found ${files.length} migration files`);

    // Get already executed migrations
    const { rows: executedMigrations } = await pool.query(
      'SELECT migration_name FROM schema_migrations'
    );
    const executedSet = new Set(executedMigrations.map((r: any) => r.migration_name));

    // Run pending migrations
    for (const file of files) {
      if (executedSet.has(file)) {
        console.log(`✓ ${file} (already executed)`);
        continue;
      }

      console.log(`Running migration: ${file}...`);
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');

      await pool.query('BEGIN');
      try {
        await pool.query(sql);
        await pool.query(
          'INSERT INTO schema_migrations (migration_name) VALUES ($1)',
          [file]
        );
        await pool.query('COMMIT');
        console.log(`✓ ${file} completed successfully`);
      } catch (error) {
        await pool.query('ROLLBACK');
        console.error(`✗ ${file} failed:`, error);
        throw error;
      }
    }

    console.log('\nAll migrations completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigrations();
