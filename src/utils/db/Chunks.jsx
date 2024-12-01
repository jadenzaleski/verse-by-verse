import { getDBInstance } from './Instance';
import log from '../Logger';

class Chunks {
  static instance;

  constructor() {
    if (!Chunks.instance) {
      this.db = null;
      Chunks.instance = this;
    }
    return Chunks.instance;
  }

  async init() {
    if (!this.db) {
      this.db = await getDBInstance();
    }
  }

  async initTable() {
    log.debug('[DB] Creating Chunks table if it doesnt exist');
    try {
      const result = await this.db.execute(
        `
      CREATE TABLE IF NOT EXISTS Chunks (
          chunk_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          chunk_name TEXT NOT NULL,
          created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          updated_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
      );
    `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error creating Chunks table: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const chunks = new Chunks();
export default chunks;
