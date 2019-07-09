const PouchDB = require('pouchdb');

(async () => {
  try {
    const local = new PouchDB('http://localhost:5984/feed');
    process.stdin.resume();
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', async (data) => {
      await local.put({ data, _id: `feed_${Date.now()}` });
    });
  } catch (error) {
    console.log(error);
  }
})()