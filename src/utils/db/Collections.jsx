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

  async getAll() {
    log.debug('[DB] Getting all collections');

    try {
      const result = await this.db.execute(
        `
            SELECT * FROM Collections;
        `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error getting all collections: ${error}`);
      return { ok: false, error: error };
    }
  }

  async add(name) {
    log.debug('[DB] Adding ' + name + ' to collections');

    try {
      const result = await this.db.execute(
        `
            INSERT INTO Collections (collection_name)
            VALUES (?)
        `,
        [name],
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error adding ${name} to collections: ${error}`);
      return { ok: false, error: error };
    }
  }

  async delete(collection_id) {
    log.debug('[DB] Deleting collection ' + collection_id);

    try {
      const result = await this.db.execute(
        `
            DELETE FROM Collections WHERE collection_id = ${collection_id};
        `,
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error deleting collection: ${error}`);
      return { ok: false, error: error };
    }
  }

  async getContents(collection_id) {
    log.debug('[DB] Getting contents of collection: ' + collection_id);

    try {
      const result = await this.db.execute(
        `
            WITH Combined AS (
                SELECT
                    'verse' AS type,
                    v.verse_id AS id_value,
                    v.book,
                    v.chapter,
                    v.verse,
                    v.updated_at,
                    v.created_at,
                    NULL AS chunk_name
                FROM Verses v
                         LEFT JOIN CollectionItems ci ON v.verse_id = ci.verse_id
                WHERE (ci.collection_id = ? OR ? = -1)
                  AND v.verse_id NOT IN (SELECT cv.verse_id FROM ChunkVerses cv)

                UNION ALL

                SELECT
                    'chunk' AS type,
                    c.chunk_id AS id_value,
                    NULL AS book,
                    NULL AS chapter,
                    NULL AS verse,
                    c.updated_at,
                    c.created_at,
                    c.chunk_name
                FROM Chunks c
                         LEFT JOIN CollectionItems ci ON c.chunk_id = ci.chunk_id
                WHERE (ci.collection_id = ? OR ? = -1)
            )
            SELECT
                row_number() OVER (ORDER BY id_value) AS id,
                type,
                id_value,
                book,
                chapter,
                verse,
                updated_at,
                created_at,
                chunk_name
            FROM Combined ORDER BY created_at;

        `,
        [collection_id, collection_id, collection_id, collection_id],
      );

      return { ok: true, response: result };
    } catch (error) {
      log.error(`[DB] Error getting contents for collection: ${error}`);
      return { ok: false, error: error };
    }
  }
}

const collections = new Collections();
export default collections;
