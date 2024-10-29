import {getDBInstance} from './Instance';
import log from '../Logger';
import {EXPONENT, SCALING_FACTOR} from '../Globals';

export async function initTable() {
  const db = await getDBInstance();
  log.debug('[DB] Creating Users table if it doesnt exist');
  // Create the user table if it doesn't already exist
  return await db.execute(`
      CREATE TABLE IF NOT EXISTS Users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                xp INTEGER DEFAULT 0,
                current_streak INTEGER DEFAULT 0,
                max_streak INTEGER DEFAULT 0,
                avatar_id INTEGER DEFAULT 0,
                force_login INTEGER DEFAULT 0,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            );
    `);
}

export async function level() {
  const db = await getDBInstance();
  try {
    const result = await db.execute(
      `SELECT xp
       FROM Users
       LIMIT 1;`,
    );

    log.debug('Query results:', result);

    if (result.rows.length > 0) {
      const xp = result.rows[0].xp;
      log.debug('XP:', xp);

      // Calculate level based on XP
      const calculatedLevel = Math.floor(Math.pow(xp / SCALING_FACTOR, 1 / EXPONENT));
      log.debug(`Calculated Level: ${calculatedLevel}`);

      return calculatedLevel; // Return the calculated level
    } else {
      log.error(`[DB] No user found in the database.`);
    }
  } catch (error) {
    log.error(`[DB] Error while retrieving user level: ${error}`);
    throw error; // Re-throw the error after logging
  }
}

function nextLevelXp(level) {
  return Math.floor(SCALING_FACTOR * Math.pow(level + 1, EXPONENT)) + 1;
}

function currentLevelXp(level) {
  return Math.floor(SCALING_FACTOR * Math.pow(level, EXPONENT));
}
