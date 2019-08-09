const PouchDB = require('pouchdb');

(async () => {
  try {
    const local = new PouchDB('http://localhost:5984/feed');
    process.stdin.resume();
    process.stdin.setEncoding('utf8');
    let buffer = "";
    process.stdin.on('data', async (data) => {
      buffer += data;
      if (data.endsWith("\n")){
        const pro = local.put({ data : buffer, _id: `feed_${Date.now()}` });
        buffer = "";
        await pro;
      }
    });
  } catch (error) {
    console.log(error);
  }
})()