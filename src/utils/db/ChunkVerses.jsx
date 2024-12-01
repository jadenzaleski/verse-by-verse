import { getDBInstance } from './Instance';
import log from '../Logger';

class ChunkVerses {
  static instance;

  constructor() {
    if (!ChunkVerses.instance) {
      this.db = null;
      ChunkVerses.instance = this;
    }
    return ChunkVerses.instance;
  }

  async init() {
    if (!this.db) {
      this.db = await getDBInstance();
    }
  }

  async initTable() {
    log.debug('[DB] Creating ChunkVerses table if it doesnt exist');
    try {
      const result = await this.db.execute(
        `
        CREATE TABLE IF NOT EXISTS ChunkVerses (
             chunk_id INTEGER NOT NULL,
             verse_id INTEGER NOT NULL,
             created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
             updated_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
             PRIMARY KEY (chunk_id, verse_id),
             FOREIGN KEY (chunk_id) REFERENCES Chunks(chunk_id) ON DELETE CASCADE,
             FOREIGN KEY (verse_id) REFERENCES Verses(verse_id) ON DELETE CASCADE
        );
    `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error creating ChunkVerses table: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const chunkVerses = new ChunkVerses();
export default chunkVerses;
