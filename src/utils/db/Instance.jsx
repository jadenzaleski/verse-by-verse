import {open} from '@op-engineering/op-sqlite';
import log from '../Logger';

let dbInstance = null;

export const getDBInstance = async () => {
  try {
    if (!dbInstance) {
      dbInstance = open({
        name: 'vbvDB',
      });
      log.debug('[DB] Database opened successfully!');
      log.info(`[DB] Database path: ${dbInstance.getDbPath()}`);
    }
    return dbInstance;
  } catch (error) {
    log.error('[DB] Error opening the database:', error);
    throw error; // Re-throw the error if there's a failure opening the DB
  }
};

export const closeDBInstance = async () => {
  if (dbInstance) {
    await dbInstance.close();
    dbInstance = null;
    log.debug('[DB] Database closed successfully!');
  }
};

export const deleteDB = async () => {
  if (dbInstance) {
    await dbInstance.delete();
    log.debug('[DB] Database deleted successfully!');

  }
}

// Function to test database interaction using the singleton instance
export const testDatabase = async () => {
  try {
    // Get the singleton instance of the database
    const db = await getDBInstance();

    // Create a sample table if it doesn't already exist
    await db.execute(`
      CREATE TABLE IF NOT EXISTS TestTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value INTEGER
      )
    `);
    log.info('Table created successfully!');

    // Insert a row into the table
    await db.execute(
      `
      INSERT INTO TestTable (name, value) VALUES (?, ?)
    `,
      ['Sample Name', 42],
    );
    console.log('Row inserted successfully!');

    // Query the data
    const results = await db.execute('SELECT * FROM TestTable');
    log.debug('Query results:', results);

  } catch (error) {
    console.error('Error interacting with the database:', error);
  }
};
