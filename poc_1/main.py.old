import sys
import pygame
from pygame.locals import *
import time
import json
from os import listdir
from os.path import isfile, join
from random import randint
from numba import jit
from numpy import arange

pygame.init()

RED                 = (255,0,0)
GREEN               = (0,255,0)
BLUE                = (0,0,255)
WHITE               = (255,255,255)
BLACK               = (0,0,0)
X                   = 0
Y                   = 1
BIG                 = 9999999999

FEN_SIZE_X          = 1800
FEN_SIZE_Y          = 600

HALF_FEN_SIZE_X     = FEN_SIZE_X / 2

SITUATION_SIZE      = 600
THEN_SIZE           = 200
CLOCK               = 0.0

VIEW_ENABLED        = True
VIEW_SKIP_RATE      = 0.007 
GAP_COMP            = 1
GAP_BASE            = 3

BASE_START          = 1200
COMP_CIRCLE_SKIP    = 16
CIRCLE_BASE_TOLERANCE = 50

MAX_SITUATIONS      = BIG

env                 = {}

def randomColor():
    return [randint(0,255) for i in range(3)]

def prj(lapin):
    print json.dumps(lapin, indent = 2)

class SituationsComparator:
    def __init__(self, base, comp):
        self.base = base
        self.comp = comp

    def CircleCompare(self):
        self.comp_circles = []
        self.base_circles = []
        tolerance = CIRCLE_BASE_TOLERANCE
        self.match = 0
        self.not_match = 0
        for index, comp_price in enumerate(self.comp.prices):
            if index % COMP_CIRCLE_SKIP == 0:
                if abs(comp_price - self.base.prices[index]) < (tolerance):
                    self.match += 1
                    color = GREEN
                else:
                    self.not_match += 1
                    color = RED
                self.comp_circles.append([comp_price, int(tolerance) / 2, color])
                self.base_circles.append([self.base.prices[index], int(tolerance) / 2, color])
                tolerance += -0.92

class Situation:
    def __init__(self, prices, then):
        self.prices = prices
        self.then_prices = then

class Situations:
    def __init__(self, fi):
        self.data = []
        self.load(fi)
        self.rendu = 0
        self.situation = None
        self.setSituation()

    def load(self, fi):
        with open(fi, "r") as f:
            self.data = [x['open'] for x in json.loads(f.read())['Data']]
    
    def setSituation(self, index = False):
        if not index:
            index = self.rendu
        self.situationRaw = self.data[index:][:SITUATION_SIZE]
        minus, maxus = min(self.situationRaw) , max(self.situationRaw)
        self.situationPoints =  [((price - minus) * 100) / (maxus - minus) for price in self.situationRaw]        
        self.situationRawThen = self.data[index+SITUATION_SIZE:][:THEN_SIZE]
        minusThen, maxusThen = min(self.situationRawThen) , max(self.situationRawThen)
        self.situationPointsThen =  [((price - minusThen) * 100) / (maxusThen - minusThen) for price in self.situationRawThen]

        self.situation = Situation(self.situationPoints, self.situationPointsThen)

    def reset(self, index = 0):
        self.rendu = index
        self.setSituation(index = index)

    def forward(self, nbr = 1):
        try:
            self.rendu += 1 * nbr
            self.setSituation(index = self.rendu)
            return True if len(self.situationPoints) == SITUATION_SIZE else False
        except:
            return False

class Viewer:
    def __init__(self):
        self.skip_index = 0
        self.skip_rate = 500
        self.fen = pygame.display.set_mode((FEN_SIZE_X, FEN_SIZE_Y))
        self.last_blit = time.time()
    
    def isNotSkipped(func):
        def decor(self, *args, **kwargs):
            if time.time() - self.last_blit > VIEW_SKIP_RATE or args[0] == True:
                func(self, *args, **kwargs)
        return decor

    def getGapX(self, array):
        return FEN_SIZE_X / len(array)

    # @isNotSkipped
    def clear(self, color = WHITE):
        self.fen.fill(color)

    def drawCircles(self, data, start = [0,0], size = [HALF_FEN_SIZE_X,FEN_SIZE_Y] , thick = 2):
        gap = float(size[X]) / float(len(data))
        x = 0
        for index ,point in enumerate(data):
            radius = FEN_SIZE_Y * point[1] / 100
            self.drawCircle([int(x) + start[X], int(size[Y] - (point[0] / 100 * size[Y]))], radius, color = point[2])
            x += gap
    
    # @isNotSkipped
    def drawGraph(self, data, start = [0,0], size = [HALF_FEN_SIZE_X,FEN_SIZE_Y] , color = BLACK, thick = 2):
        gap = float(size[X]) / float(len(data))
        final = []
        x = 0
        for index, point in enumerate(data):
            final.append([int(x) + start[X],  size[Y] - (point / 100 * size[Y])])
            x += gap
        self.drawLines(final, color = color, thick = thick)

    # @isNotSkipped
    def drawLines(self, data, thick = 1, color = BLACK):
        pygame.draw.lines(self.fen, color, False, data, thick)

    # @isNotSkipped
    def drawCircle(self, pos, radius, color = BLACK):
        pygame.draw.circle(self.fen, color, pos, radius, 1)

    # @isNotSkipped
    def blit(self, force):
        pygame.display.update()
        self.last_blit = time.time()
        



class Baker:
    def __init__(self):
        self.situations = []
        fis = [f for f in listdir('data') if isfile(join('data', f))]
        index = 0
        for fi in fis:
            if index == MAX_SITUATIONS:
                break
            try:
                self.situations.append(Situations('data/'+fi))
                index += 1
            except:
                pass

    def bake(self, sit_base):
        self.view = Viewer()
        sit_base.reset(index = BASE_START)
        totalCompared = 0
        self.view.clear()
        time_last_blit = time.time()
        for sit in self.situations:
            while sit.forward(nbr = GAP_COMP):
                comparator = SituationsComparator(sit_base.situation, sit.situation)
                comparator.CircleCompare()
                if comparator.not_match == 0 :#or True:
                # if (time.time() - time_last_blit > 0.05):
                    time_last_blit = time.time()
                    # self.view.clear()
                    self.view.drawCircles(comparator.comp_circles)
                    self.view.drawCircles(comparator.base_circles)
                    self.view.drawGraph(sit_base.situation.prices)
                    self.view.drawGraph(sit.situation.prices, color = BLUE,thick=1)
                    self.view.drawGraph(sit_base.situation.then_prices,start=[HALF_FEN_SIZE_X,0],thick=4)
                    self.view.blit(False)
                if comparator.not_match == 0:
                    self.view.drawGraph(sit_base.situation.then_prices,start=[HALF_FEN_SIZE_X,0], thick=4)
                    self.view.drawGraph(sit.situation.then_prices, color = randomColor(), start=[HALF_FEN_SIZE_X,0], thick=1)
                    sit.forward(nbr = 50)
                    self.view.blit(True)
                    # time.sleep(5)
                time.sleep(CLOCK)
                totalCompared += 1
                if totalCompared % 500 == 0:
                    print totalCompared

if __name__ == "__main__":
    VIEW_ENABLED = True if not "-q" in sys.argv else False
    # v = Main()
    b = Baker()
    b.bake(Situations("eth_btc"))
    time.sleep(BIG)






# class Main:
#     def __init__(self):
#         global env
#         if VIEW_ENABLED:
#             self.view = Viewer()
#             env['view'] = self.view
#         s_base = Situations("eth_btc")
#         s_comp = Situations('ltc_btc')
#         while True:
#             # time_start = time.time()
#             while True:
#                 self.view.clear()
#                 if not s_comp.forward(nbr = GAP_COMP): break
#                 comparator = SituationsComparator(s_base.situation, s_comp.situation)
#                 comparator.CircleCompare()
#                 if VIEW_ENABLED:
#                     self.view.drawCircles(comparator.comp_circles)
#                     self.view.drawCircles(comparator.base_circles)
#                     self.view.drawGraph(s_base.situation.prices)
#                     self.view.drawGraph(s_comp.situation.prices, color = BLUE)
#                     self.view.blit(False)
#                     if comparator.not_match == 0:
#                         self.view.blit(True)
#                         time.sleep(BIG)
                        
#                 time.sleep(CLOCK)
#             s_comp.reset()
#             if not s_base.forward(nbr = GAP_BASE): break
#             # time_diff = time.time() - time_start