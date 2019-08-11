from coreBridge import Data
import random

ACTION_BUY = 0
ACTION_SELL = 1

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5

class Simulation:
    rake = 0.00075
    totalRake = 0
    nbrMatchs = 1500
    score = 0
    good = 0
    bad = 0
    fd = {}
    totalPlay = 1
    totalRealChange = 0
    totalLine = 0
    def __init__(self, simPath, size):
        self.size = size
        for coin in Data.getCoinList():
            self.fd[coin] = open("./data/{}".format(coin) , "rb")
        with open(simPath, "r") as f:
            sim = f.read().split("#")[:-1]
        for si in sim:
            self.sit = {}
            sp = si.split(":")
            spp = sp[0].split("|")
            self.sit["srcName"] = spp[0]
            self.sit["srcData"] = Data.getSituation(size * 2, self.sit["srcName"],int(spp[1]))
            self.sit["matchs"] = list(self.filterMatchs(list(Data.getDataFromMatch(sp[1], size * 2, self.nbrMatchs, fd=self.fd))))
            self.play()
            # break

    def filterMatchs(self, matchs):
        for match in matchs:
            if abs(self.sit["srcData"][0][DATE] - match["data"][0][DATE]) < self.size * 2:
                continue
            yield match

    def play(self):
        closeCursor = 100
        up = 1
        down = 1
        diff = 0
        scoreMatch = 0
        for match in self.sit["matchs"]:
            scoreMatch += match['score']
            change = 100 - (match["data"][self.size][OPEN] / match["data"][self.size + closeCursor][OPEN] * 100)
            res = 100 - (match["data"][self.size][OPEN] / match["data"][self.size + closeCursor][OPEN] * 100)
            if res > 0:
                up += abs(res) 
            else : 
                down += abs(res) 

            # for price in match["data"][:self.size]:
            #     res = 100 - (match["data"][self.size][OPEN] / price[OPEN] * 100)
            #     if res > 0:
            #         up += abs(res) 
            #     else : 
            #         down += -abs(res) 

        realChange = 100 - (self.sit['srcData'][self.size][OPEN] / self.sit['srcData'][self.size + closeCursor][OPEN] * 100)
        self.totalLine += 1
        self.totalRealChange += realChange
        diff =   (up  / down) * 100
        scoreMatch = scoreMatch / self.nbrMatchs
        
        if (up > down and up / down > 1.8):
            self.totalPlay += 1
            if (up > down and realChange > 0) or (down > up and realChange < 0):
            # if (random.randint(0,1) == 0):
                self.score += abs(realChange)
                self.good += abs(realChange)
                color = '\33[5;37;42m'
            else:
                self.score += -abs(realChange)
                self.bad += abs(realChange)
                color = '\33[1;37;41m'
            scoreage = (self.good - self.bad) / self.totalPlay * 100
        else:
            color = '\33[1;37;40m'
            scoreage = 0
        scoreage = (self.good - self.bad) / self.totalPlay * 100
        print("{} match : {:8} score : {:7.1f}% {:13} up: {:5}  down : {:5} diff : {:5} real : {:5.2f} godd: {:6.0f} bad {:6.0f} Change : {:5.2f}".format(color,int(scoreMatch),scoreage ,self.sit["srcName"],int(up), int(down),int(diff), realChange, self.good, self.bad, self.totalRealChange / self.totalLine * 100))


if __name__ == "__main__":
    Simulation("./sim2", 400)