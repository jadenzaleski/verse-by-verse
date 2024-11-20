import log from '../Logger';
import {getDBInstance} from './Instance';
import Users from './Users';
import {initTable} from './Verses';

export async function initTables() {
  await Users.init();
  return {users: await Users.initTable(), verses: await initTable()};
}
