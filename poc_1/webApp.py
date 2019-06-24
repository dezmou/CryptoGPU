import asyncio
import websockets
import time

class WebApp:

    def loop(self):
        time.sleep(0.05)
        return "it work ! at " + str(time.time())

    def __init__(self):
        with open("/var/www/html/time", "w") as f:
            f.write(str(time.time()))
        start_server = websockets.serve(self.hello, 'localhost', 5555)
        asyncio.get_event_loop().run_until_complete(start_server)
        asyncio.get_event_loop().run_forever()


    async def hello(self, websocket, path):
        while True:
            res = self.loop()
            await websocket.send(res)

if __name__ == "__main__":
    app = WebApp()