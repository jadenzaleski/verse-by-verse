import {getDBInstance} from './Instance';
import log from '../Logger';
import { EMAIL_REGEX, EXPONENT, PASSWORD_REGEX, SCALING_FACTOR } from '../Globals';

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

    if (result.rows.length > 0) {
      const xp = result.rows[0].xp;
      log.debug(`[DB] Level calculation xp to use: ${xp}`);

      const calculatedLevel = Math.floor(Math.pow(xp / SCALING_FACTOR, 1 / EXPONENT));
      log.debug(`[DB] Calculated Level: ${calculatedLevel}`);

      return calculatedLevel;
    } else {
      log.error(`[DB] No user found in the database when attempting to retrieve the level`);
    }
  } catch (error) {
    log.error(`[DB] Error while retrieving user level: ${error}`);
    throw error;
  }
}
// Calculate the xp needed to reach the next level
export async function nextLevelXp() {
  const nlxp = Math.floor(SCALING_FACTOR * Math.pow((await level()) + 1, EXPONENT)) + 1;
  log.debug(`[DB] Calculated next level xp: ${nlxp}`);
  return nlxp;
}
// Calculate and return the XP at which the current level started
export async function currentLevelXp() {
  const clxp = Math.floor(SCALING_FACTOR * Math.pow(await level(), EXPONENT));
  log.debug(`[DB] Calculated current level xp: ${clxp}`);
  return clxp;
}

export async function getUser() {
  const db = await getDBInstance();
  try {
    const result = await db.execute(
      `SELECT *
       FROM Users
       LIMIT 1;`,
    );

    if (result.rows.length > 0) {
      log.debug('USER:', result.rows[0]);
      return result.rows[0];
    } else {
      log.error(`[DB] No user found in the database when attempting to retrieve the user`);
    }
  } catch (error) {
    log.error(`[DB] Error while getting the user: ${error}`);
  }
}

export async function createUser(name, email, password) {
  const db = await getDBInstance();
  const emailLower = email.toLowerCase();

  try {
    if (!EMAIL_REGEX.test(emailLower)) {
      log.warn(`[DB] Invalid email address: ${email}`);
      return `Invalid email address: ${email}`;
    }

    //requires at least one digit (0-9) or a non-word character
    if (!PASSWORD_REGEX.test(password)) {
      log.warn(`[DB] Invalid password: ${password}`);
      return `Password must contain at least one digit or symbol`;
    }

    let hashedPassword = 'hashed_password';

    const result = await db.execute(
      `INSERT INTO Users (name, email, password)
       VALUES (?, ?, ?);`,
      [name, emailLower, hashedPassword],
    );

    log.debug(`[DB] User ${name} created successfully`);
    return result;
  } catch (error) {
    log.error(`[DB] Error creating the user: ${error}`);
  }
}
