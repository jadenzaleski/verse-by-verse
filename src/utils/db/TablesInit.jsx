import Users from './Users';
import Verses from './Verses';

export async function initTables() {
  await Users.init();
  await Verses.init();
  return { users: await Users.initTable(), verses: await Verses.initTable() };
}
