import time
import couchdb
import struct
import json
import random
import os

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5

class Data:
    def getSituation(size, coinName, indexMinute, fd=None):
        if fd:
            fd[coinName].seek(indexMinute * 6 * 8)
            return list(struct.iter_unpack("qddddd", fd[coinName].read(size * 6 * 8)))
        else:
            with open("./data/{}".format(coinName) , "rb") as f:
                f.seek(indexMinute * 6 * 8)
                return list(struct.iter_unpack("qddddd", f.read(size * 6 * 8)))

    def getDataFromMatch(match, size, maxNbrScore, fd=None):
        nbr = 0
        for line in match.split("\n")[:-1][1:]:
            nbr += 1
            sp = line.split("|")
            yield {
                "score" : float(sp[0]),
                "name" : sp[1],
                "data" : Data.getSituation(size, sp[1], int(sp[2]), fd)
            }
            if nbr == maxNbrScore:
                return

    def getCoinList():
        with open("coinList", "r") as f:
            return f.read().strip().split(" ")

class CoreBridge:
    def __init__(self):
        self.couch = couchdb.Server()        
        self.queryDb = self.couch["cuda_core_query"]
        self.resDb = self.couch["cuda_core_response"]

    def getSituation(self,size, coinName, indexMinute):
        with open("./data/{}".format(coinName) , "rb") as f:
            f.seek(indexMinute * 6 * 8)
            return list(struct.iter_unpack("qddddd", f.read(size * 6 * 8)))

    def getMatchs(self, sit):
        idd = self.queryDb.save({"data" : json.dumps(sit)})[0]
        while True:
            res = self.resDb.get(idd)
            if res:
                self.resDb.delete(self.resDb[idd])
                return res['data']
            time.sleep(0.1)
    
    def compare(self, sit):
        return list(Data.getDataFromMatch(self.getMatchs(sit), len(sit)))

if __name__ == "__main__":
    c = CoreBridge()
    coins = Data.getCoinList()
    i = 0
    with open("sim2", "a") as f:
        while True:
            i += 1
            coin = coins[random.randint(0,len(coins) - 1)]
            size = os.stat("./data/{}".format(coin)).st_size / 6 / 8
            minuteId = random.randint(0, size - 5000);
            sit = Data.getSituation(400, coin, minuteId)
            res = c.getMatchs(sit)
            f.write("{}|{}:\n{}#".format(coin, minuteId, res))
            print(i)