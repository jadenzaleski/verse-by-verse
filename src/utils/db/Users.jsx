import {getDBInstance} from './Instance';
import log from '../Logger';
import {EMAIL_REGEX, EXPONENT, PASSWORD_REGEX, SCALING_FACTOR} from '../Globals';

export async function initTable() {
  const db = await getDBInstance();
  const timestamp = new Date().toISOString();
  log.debug('[DB] Creating Users table if it doesnt exist');
  try {
    const result = await db.execute(
      `
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
                created_at TEXT DEFAULT '${timestamp}',
                updated_at TEXT DEFAULT '${timestamp}'
            );
    `,
    );

    return {ok: true, response: result};
  } catch (error) {
    log.error(`[DB] Error creating Users table: ${error}`);
    return {ok: false, error: error};
  }
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
      // log.debug(`[DB] Level calculation xp to use: ${xp}`);

      const calculatedLevel = Math.floor(Math.pow(xp / SCALING_FACTOR, 1 / EXPONENT));
      // log.debug(`[DB] Calculated Level: ${calculatedLevel}`);

      return calculatedLevel;
    } else {
      log.error(`[DB] No user found in the database when attempting to retrieve the level`);
      return {ok: false, error: `No user found in the database when attempting to retrieve the level`};
    }
  } catch (error) {
    log.error(`[DB] Error while retrieving user level: ${error}`);
    return {ok: false, error: error};
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
      return {ok: true, response: result.rows[0]};
    } else {
      log.error(`[DB] No user found in the database when attempting to retrieve the user`);
      return {ok: false, error: `No user found in the database when attempting to retrieve the user`};
    }
  } catch (error) {
    log.error(`[DB] Error while getting the user: ${error}`);
    return {ok: false, error: error};
  }
}

function validateEmail(email) {
  if (!EMAIL_REGEX.test(email)) {
    log.warn(`[DB] Invalid email address: ${email}`);
    return false;
  } else {
    return true;
  }
}

function validatePassword(password) {
  if (!PASSWORD_REGEX.test(password)) {
    log.warn(`[DB] Invalid password: ${password}`);
    return false;
  } else {
    return true;
  }
}

export async function createUser(name, email, password) {
  const db = await getDBInstance();
  const emailLower = email.toLowerCase();

  try {
    if (!validateEmail(emailLower)) {
      return {ok: false, error: `Invalid email address: ${email}`};
    }

    //requires at least one digit (0-9) or a non-word character
    if (!validatePassword(password)) {
      return {ok: false, error: `Password must be 8 >= characters and contain at least one digit or symbol`};
    }

    let hashedPassword = 'hashed_password';

    const result = await db.execute(
      `INSERT INTO Users (name, email, password)
       VALUES (?, ?, ?);`,
      [name, emailLower, hashedPassword],
    );

    log.debug(`[DB] User ${name} created successfully`);
    return {ok: true, response: result};
  } catch (error) {
    if (error.message && error.message.includes('UNIQUE constraint failed: Users.email')) {
      log.warn(`[DB] User creation failed: Email already exists`);
      return {ok: false, error: 'This email is already in use. Please choose another one.'};
    } else {
      log.error(`[DB] Error creating the user: ${error}`);
      return {ok: false, error: error.message || 'Unknown error'};
    }
  }
}

export async function updateUser(data, increments) {
  const db = await getDBInstance();

  try {
    // Remove restricted fields if present
    if (data.user_id || data.created_at || data.updated_at) {
      log.warn(`[DB] You cannot update the following fields: user_id, created_at, updated_at`);
    }
    delete data.user_id;
    delete data.created_at;
    delete data.updated_at;

    // Validate email if provided
    if (data.email && !validateEmail(data.email)) {
      return {ok: false, error: `Invalid email address: ${data.email}`};
    }

    // Validate password if provided
    if (data.password && !validatePassword(data.password)) {
      return {ok: false, error: `Password must contain at least one digit or symbol`};
    }

    // Hash the password if it needs to be updated
    if (data.password) {
      data.password = 'hashed_password'; // TODO: Replace with actual hashing logic
    }

    // Add `updated_at` field with the current timestamp
    data.updated_at = new Date().toISOString();

    // Convert object keys and values for the SQL update
    const fields = Object.keys(data);
    const values = Object.values(data);

    // Construct the `SET` clause dynamically for standard updates
    let setClause = fields.map(field => `${field} = ?`).join(', ');

    // Handle increments
    if (increments) {
      const incrementFields = Object.keys(increments);
      incrementFields.forEach(field => {
        setClause += `, ${field} = ${field} + ?`;
        values.push(increments[field]);
      });
    }

    if (setClause.trim() === '') {
      log.warn(`[DB] No allowed fields provided to update`);
      return {ok: false, error: `No allowed fields provided to update`};
    }

    const userResult = await db.execute(`SELECT user_id FROM Users LIMIT 1;`);

    if (userResult.rows.length === 0) {
      log.warn(`[DB] No user found in the database`);
      return {ok: false, error: `No user found in the database when updating the user`};
    }

    const userId = userResult.rows[0].user_id;
    values.push(userId);

    const query = `UPDATE Users SET ${setClause} WHERE user_id = ?;`;
    const result = await db.execute(query, values);

    log.debug(`[DB] Updated user with ID ${userId}: ${JSON.stringify(setClause)}`);
    return {ok: true, response: result};
  } catch (error) {
    log.error(`[DB] Error updating user: ${error}`);
    return {ok: false, error: error};
  }
}

export async function userExists() {
  const db = await getDBInstance();
  try {
    const result = await db.execute(`SELECT 1 FROM Users LIMIT 1;`);
    // If a row exists, the user exists in the database
    return result.rows.length > 0;
  } catch (error) {
    console.error(`[DB] Error checking if user exists: ${error}`);
    throw error;
  }
}
