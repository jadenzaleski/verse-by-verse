import log from '../Logger';
import { getDBInstance } from './Instance';
import { initTable } from './Users';

export async function initTables() {
  await initTable();
}

