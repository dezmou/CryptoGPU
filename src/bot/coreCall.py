import time
import couchdb
import struct
import json

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5

class CoreCall:
    def __init__(self):
        self.couch = couchdb.Server()        
        self.queryDb = self.couch["cuda_core_query"]
        self.resDb = self.couch["cuda_core_response"]

    def getSituation(self,size, coinName, indexMinute):
        with open("./data/{}".format(coinName) , "rb") as f:
            f.seek(indexMinute * 6 * 8)
            return list(struct.iter_unpack("qddddd", f.read(size * 6 * 8)))
            
    def callCore(self, sit):
        idd = self.queryDb.save({"data" : json.dumps(sit)})[0]
        while True:
            res = self.resDb.get(idd)
            if res:
                print (res['data'])
                self.resDb.delete(self.resDb[idd])
                return res['data']
            time.sleep(0.1)

if __name__ == "__main__":
    c = CoreCall()
    sit = c.getSituation(100, "ETHBTC", 1)
    c.callCore(sit)
    # c.callCore()