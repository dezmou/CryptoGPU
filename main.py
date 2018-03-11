from webApp import WebApp
import time
import json
from random import randint

X               = 0
Y               = 0
DATA_TYPE_CLEAR = 0
DATA_TYPE_LINES = 1

CANVAS_SIZE     = 900
SITUATION_TIME  = 200
LINE_GAP        = 5
#CLOCK           = 0.035
CLOCK           = 0.015


def pointToGraph(y):
    return CANVAS_SIZE - y * 7

class Situation:
    def __init__(self, prices, index):
        self.index = index
        self.basePrices = prices
        self.prices = prices[index:]
        self.prices = self.prices[:SITUATION_TIME]
        self.prices = [x['open'] for x in self.prices]
        
        self.pricesPourcent =  self.pricesToPourcents(self.prices)
        self.getAcceptableLine()
        
        self.points = self.toPoints(self.pricesPourcent)
        self.minPoints = self.toPoints(self.minPourcent)
        self.maxPoints = self.toPoints(self.maxPourcent)


    def getAcceptableLine(self):
        self.maxPourcent = []
        self.minPourcent = []
        tolerance = 40
        for pourcent in self.pricesPourcent:
            self.maxPourcent.append(pourcent + tolerance)
            self.minPourcent.append(pourcent - tolerance)
            tolerance += -0.15

    def pricesToPourcents(self, prices):
        final = []
        minus = min(self.prices)
        maxus = max(self.prices)
        for price in self.prices:
            final.append(((price - minus) * 100) / (maxus - minus))
        return final

    def toPoints(self, pourcents):
        final = []
        x = 0
        for price in pourcents:
            final.append([x, pointToGraph(price)])
            x += LINE_GAP
        return final

    def forward(self):
        self.__init__(self.basePrices, self.index + 1)



class Crypt(WebApp):
    def __init__(self):
        self.lastX = 200
        self.lastY = 200
        self.btc = self.getPrices('data/btc')
        self.sit_btc = Situation(self.btc, 0)
        WebApp.__init__(self)

    def getPrices(self, fi):
        with open(fi, "r") as f:
            return json.loads(f.read())['Data']
        
    def loop(self):
        startTime = time.time()

        self.data = []
        self.data.append({'type' : DATA_TYPE_CLEAR})
        line = {
                'type' : DATA_TYPE_LINES,
                'color' : 'black',
                'points' : self.sit_btc.points
        }
        self.data.append(line)
        line2 = {
                'type' : DATA_TYPE_LINES,
                'color' : 'red',
                'points' : self.sit_btc.minPoints
        }
        self.data.append(line2)
        line3 = {
                'type' : DATA_TYPE_LINES,
                'color' : 'red',
                'points' : self.sit_btc.maxPoints
        }
        self.data.append(line3)


        self.sit_btc.forward()
        endTime = time.time()
        time.sleep(CLOCK - (endTime - startTime))
        return json.dumps(self.data)

c = Crypt()