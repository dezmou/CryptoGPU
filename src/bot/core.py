# Use core.so to process situations

import ctypes
import couchdb
import time
import json
import traceback

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5

class Core:
    def bake(self, sit):
        data = []
        for line in sit:
            for nbr in line:
                data.append(float(nbr))
        param = (ctypes.c_double * len(data))(*data)
        self.cuda.bake.restype = ctypes.c_char_p;
        return self.cuda.bake(len(sit), param);
    
    def __init__(self):
        self.cuda = ctypes.CDLL("./core.so")
        with open("coinList", "r") as f:
            coinStr = f.read()
        coinNames = coinStr.strip().split(" ")
        arg = (ctypes.c_char_p * len(coinNames))()
        arg[:] = coinNames
        self.cuda.init(len(coinNames), arg)
        self.listenCouch()

    def listenCouch(self):
        self.couch = couchdb.Server()
        self.queryDb = self.couch["cuda_core_query"]
        self.resDb = self.couch["cuda_core_response"]
        while True:
            for chien in self.queryDb:
                idd = self.queryDb[chien]["_id"]
                print("BAKE")
                res = self.bake(json.loads(self.queryDb[chien]["data"]))
                print("DONE")
                self.resDb[idd] = {"data" : res}
                self.queryDb.delete(self.queryDb[chien])
            time.sleep(0.1)

if __name__ == "__main__":
    try:
        Core()
    except Exception:
        with open("error.log", "w") as f:
            f.write(traceback.format_exc())