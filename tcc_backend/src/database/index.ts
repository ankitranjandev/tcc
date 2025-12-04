import { Pool, PoolClient } from 'pg';
import config from '../config';
import logger from '../utils/logger';

class Database {
  private pool: Pool;
  private static instance: Database;

  private constructor() {
    this.pool = new Pool({
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
      min: config.database.poolMin,
      max: config.database.poolMax,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.pool.on('connect', () => {
      logger.info('Database connection established');
    });

    this.pool.on('error', (err) => {
      logger.error('Unexpected database error', err);
    });
  }

  public static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  public getPool(): Pool {
    return this.pool;
  }

  public async query<T>(text: string, params?: any[]): Promise<T[]> {
    const start = Date.now();
    try {
      const result = await this.pool.query(text, params);
      const duration = Date.now() - start;
      logger.debug('Executed query', { text, duration, rows: result.rowCount });
      return result.rows;
    } catch (error) {
      logger.error('Query error', { text, error });
      throw error;
    }
  }

  public async getClient(): Promise<PoolClient> {
    return await this.pool.connect();
  }

  public async transaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T> {
    const client = await this.getClient();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  public async testConnection(): Promise<boolean> {
    try {
      await this.query('SELECT NOW()');
      logger.info('Database connection test successful');
      return true;
    } catch (error) {
      logger.error('Database connection test failed', error);
      return false;
    }
  }

  public async close(): Promise<void> {
    await this.pool.end();
    logger.info('Database pool closed');
  }
}

export default Database.getInstance();
