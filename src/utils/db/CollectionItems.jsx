import { getDBInstance } from './Instance';
import log from '../Logger';

class CollectionItems {
  static instance;

  constructor() {
    if (!CollectionItems.instance) {
      this.db = null;
      CollectionItems.instance = this;
    }
    return CollectionItems.instance;
  }

  async init() {
    if (!this.db) {
      this.db = await getDBInstance();
    }
  }

  async initTable() {
    log.debug('[DB] Creating CollectionItems table if it doesnt exist');
    try {
      const result = await this.db.execute(
        `
            CREATE TABLE IF NOT EXISTS CollectionItems
            (
                item_id       INTEGER PRIMARY KEY AUTOINCREMENT,
                collection_id INTEGER NOT NULL,
                verse_id      INTEGER,
                chunk_id      INTEGER,
                created_at      TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
                updated_at      TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
                UNIQUE (collection_id, verse_id),
                UNIQUE (collection_id, chunk_id),                   
                FOREIGN KEY (collection_id) REFERENCES Collections (collection_id) ON DELETE CASCADE,
                FOREIGN KEY (verse_id) REFERENCES Verses (verse_id) ON DELETE CASCADE,
                FOREIGN KEY (chunk_id) REFERENCES Chunks (chunk_id) ON DELETE CASCADE,
                CHECK ((verse_id IS NOT NULL AND chunk_id IS NULL) OR
                       (verse_id IS NULL AND chunk_id IS NOT NULL)) 
            );
        `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error creating CollectionItems table: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const collectionItems = new CollectionItems();
export default collectionItems;
