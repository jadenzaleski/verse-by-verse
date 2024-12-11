import { getDBInstance } from './Instance';
import log from '../Logger';

class Collections {
  static instance;

  constructor() {
    if (!Collections.instance) {
      this.db = null;
      Collections.instance = this;
    }
    return Collections.instance;
  }

  async init() {
    if (!this.db) {
      this.db = await getDBInstance();
    }
  }

  async initTable() {
    log.debug('[DB] Creating Collections table if it doesnt exist');
    try {
      const result = await this.db.execute(
        `
            CREATE TABLE IF NOT EXISTS Collections
            (
                collection_id   INTEGER PRIMARY KEY AUTOINCREMENT,
                collection_name TEXT NOT NULL,
                created_at      TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
                updated_at      TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
            );
        `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error creating Collections table: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const collections = new Collections();
export default collections;
