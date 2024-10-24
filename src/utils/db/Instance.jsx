import {open} from '@op-engineering/op-sqlite';

let dbInstance = null;

export const getDBInstance = async () => {
  try {
    if (!dbInstance) {
      // If no instance exists, create a new one
      dbInstance = open({
        name: 'vbvDB',
      });
      console.log('Database opened successfully!');
    }

    // Return the existing instance (whether newly created or previously existing)
    return dbInstance;
  } catch (error) {
    console.error('Error opening the database:', error);
    throw error; // Re-throw the error if there's a failure opening the DB
  }
};

export const closeDBInstance = async () => {
  if (dbInstance) {
    await dbInstance.close();
    dbInstance = null; // Reset the instance so a new connection can be created later if needed
    console.log('Database closed successfully!');
  }
};

// Function to test database interaction using the singleton instance
export const testDatabase = async () => {
  try {
    // Get the singleton instance of the database
    const db = await getDBInstance();

    // Get the database path (optional for debugging purposes)
    const path = db.getDbPath();
    console.info(`Database path: ${path}`);

    // Create a sample table if it doesn't already exist
    await db.execute(`
      CREATE TABLE IF NOT EXISTS TestTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value INTEGER
      )
    `);
    console.log('Table created successfully!');

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
    console.log('Query results:', results);

    // Optional: Close the database (only if you want to clean up at some point)
    // await closeDatabaseInstance();
  } catch (error) {
    console.error('Error interacting with the database:', error);
  }
};
