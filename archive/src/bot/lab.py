import couchdb
from coreBridge import Data

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5


class Visual:
    def sendMessage(self, data):
        idd = self.db.save({"data" : data})[0]
        print(idd)

    def printLines(self, lines):
        pass

    def printSituation(self, sit):
        pourcents = []
        volumeAvg = 0
        for line in sit["data"]:
            volumeAvg += line[VOLUME]
        volumeAvg = volumeAvg /  len(sit["data"])
        for line in sit['data']:
            pourcents.append([line[OPEN] / sit['data'][0][OPEN] * 100, line[VOLUME] / volumeAvg * 100])
        for chien in pourcents:
            print(chien)

    def __init__(self):
        self.couch = couchdb.Server()
        self.db = self.couch["cuda_lab_visual"]


class Lab:
    def __init__(self):
        self.coins = Data.getCoinList()
        self.srcSit = Data.getRandomSituation(500, coinList=self.coins)
        self.visual = Visual()
        self.visual.printSituation(self.srcSit)
        
    def bake(self):
        self.destSit = Data.getRandomSituation(100, coinList=self.coins)

if __name__ == "__main__":
    Lab()