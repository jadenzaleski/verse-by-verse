import { open } from '@op-engineering/op-sqlite';
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
