import { getDBInstance } from './Instance';
import log from '../Logger';

class Verses {
  static instance;

  constructor() {
    if (!Verses.instance) {
      this.db = null;
      Verses.instance = this;
    }
    return Verses.instance;
  }

  async init() {
    if (!this.db) {
      this.db = await getDBInstance();
    }
  }

  async initTable() {
    log.debug('[DB] Creating Verses table if it doesnt exist');
    try {
      const result = await this.db.execute(
        `
      CREATE TABLE IF NOT EXISTS Verses (
          verse_id INTEGER PRIMARY KEY AUTOINCREMENT,
          book_id INTEGER NOT NULL,
          translation TEXT NOT NULL,
          book TEXT NOT NULL,
          chapter INTEGER NOT NULL,
          verse INTEGER NOT NULL,
          text TEXT NOT NULL,
          progress REAL DEFAULT 0.0,
          last_practiced TEXT,
          created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
          updated_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
      );
    `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error creating Verses table: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const verses = new Verses();
export default verses;
