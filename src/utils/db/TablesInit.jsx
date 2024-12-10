import Users from './Users';
import Verses from './Verses';
import Chunks from './Chunks';
import ChunkVerses from './ChunkVerses';
import Collections from './Collections';
import CollectionItems from './CollectionItems';

export async function initTables() {
  await Users.init();
  await Verses.init();
  await Chunks.init();
  await ChunkVerses.init();
  await Collections.init();
  await CollectionItems.init();

  return {
    users: await Users.initTable(),
    verses: await Verses.initTable(),
    chunks: await Chunks.initTable(),
    chunkVerses: await ChunkVerses.initTable(),
    collections: await Collections.initTable(),
    collectionItems: await CollectionItems.initTable(),
  };
}
