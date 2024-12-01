import Users from './Users';
import Verses from './Verses';
import Chunks from './Chunks';

export async function initTables() {
  await Users.init();
  await Verses.init();
  await Chunks.init();
  return { users: await Users.initTable(), verses: await Verses.initTable(), chunks: await Chunks.initTable() };
}
