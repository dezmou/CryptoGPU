const { propagandeServer } = require("propagande")
const express = require("express");

(async () => {


  const app = express();
  app.listen(4000)

  const propagandeApp = await propagandeServer({
    appName: "cuda",
    admin: {
      name: "admin",
      password: "admin"
    },
    app,
    expressPort: 4000
  })
  await new Promise(resolve => setTimeout(resolve, 3000));
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  stack = [];
  process.stdin.on('data', async (data) => {
    stack.push(data);
    await propagandeApp.callRoute("printSituation", data.split("\n").map(line => line.split(" ")));
  });

})()
