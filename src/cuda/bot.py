import traceback
from time import sleep, time
from binanceCred import api, secret 
from binance.client import Client
import struct
import os
import random

# diff < -100 stepClose 5
# diff < -70 stepClose 7
# diff <> 140 stepClose 8

ACTION_BUY = 0
ACTION_SELL = 1

colors = [
'\33[37m',
'\33[31m',
'\33[32m',
'\33[33m',
'\33[34m',
'\33[35m',
'\33[31m',
'\33[36m',

]

def strColor(string):
    res = ""
    for i, data in enumerate(string.split("|")):
        res += colors[i]+" " + data
    return res
    

class Simulator:
    coinName = ""
    rake = 0.00075
    # rake = 0.000
    totalRake = 0
    nbrPlay = 0
    nbrMinutes = 0
    def __init__(self):
        self.bank = 0
        self.stepClose = 9
        self.maxDiff = -80
        self.fakeBank = 0

    def trade(self,amount, action, stepClose):
        realEnd = self.minute.real.prices[stepClose]
        if (abs(realEnd) > 50): return 0
        rake = (amount * self.rake)
        amount += -rake
        if action == ACTION_BUY:
            net = realEnd * amount * 0.01
        else:
            net = realEnd * -amount * 0.01
        rake = ((amount + net) * self.rake)
        self.totalRake += rake
        net += -rake
        return net


    def randomEngine(self):
        return self.trade(1000, random.randint(0,1), 0)

    def engine(self):
        up = 0
        down = 0
        for coin in self.minute.preds:
            for price in coin.prices:
                # if price < 0: down += 1
                # if price > 0: up += 1
                if price < 0: 
                    down += abs(price)
                if price > 0: 
                    up += abs(price)
        diff = up - down 
        if abs(self.minute.real.prices[self.stepClose]) > 10: return 0
        self.fakeBank += 1000 * self.minute.real.prices[self.stepClose] * 0.01
        with open("boot", "a") as f:
            f.write("{} Coin : {:12} | Play : {:12}| up : {:12}| down : {:12}| diff : {:12}\n".format(time(),self.coinName, self.nbrPlay, up, down, diff))
        if up > 310 and down < 150:
            return 1
            self.nbrPlay += 1

        self.nbrMinutes += 1
        return 0

    def play(self, minute):
        self.minute = minute
        return self.engine()
        # print self.bank


class Coin:
    def __init__(self, string):
        sp = string.replace("(", ";").replace(")", "").split(";")[:-1]
        self.coinI = sp[0]
        self.cursor = sp[1]
        self.prices = [float(x) for x in sp[2:]]

class Minute:
    def __init__(self, line):
        spp = line.replace("-->", "|").split("|")[:-1]
        self.real = Coin(spp[0])
        self.preds = [Coin(x) for x in spp[1:]]

# class Main:
#     def __init__(self):
#         with open("result", "r") as f:
#             lines = f.readlines()
#         minutes = []
#         sim = Simulator()
#         sim.stepClose = 9
#         sim.maxDiff = 260
#         for line in lines:
#             minute = Minute(line)
#             minutes.append(minute)
#             sim.play(minute)
#             # break
#         li = []


client = Client(api, secret)

TIME = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4 
VOLUME = 5
CLOSE_TIME = 6
QUOTE_ASSET_VOLUME = 7
NUMBER_TRADES = 8
TAKER_BUY_BASE_ASSET_VOLUME = 9
TAKER_BUY_QUOTE_ASSET_VOLUME = 10
CAN_BE_IGNORED = 11

prices = client.get_all_tickers()
coins = []
for price in prices:
    coin = price["symbol"]
    if coin.endswith("BTC"):
        coins.append(coin)
    
while True:
    for coin in coins:
        try:
            print coin
            klines = client.get_historical_klines(coin, Client.KLINE_INTERVAL_1MINUTE, "500 minutes ago UTC")
            binary = ""
            # if (float(klines[0][OPEN]) < 0.000620) :
            #     continue
            for line in klines:
                for value in [float(line[OPEN]),float(line[HIGH]),float(line[LOW]),float(line[CLOSE]),float(line[VOLUME])]:
                    # binary += struct.pack('d', value)
                    binary += struct.pack('d', value)
            os.system("rm ./tmp");
            os.system("rm ./actual");
            with open("actual", "wb") as f:
                f.write(binary)
            wait = 0
            while True:
                try:
                    with open("./tmp", "r") as f:
                        succes = True
                        data = f.read()
                        break
                except Exception as e:
                    wait += 1
                    succes = False
                    if wait > 20:
                        break
                    pass
                sleep(1)
            if not succes: continue
            sim = Simulator()
            sim.stepClose = 9
            sim.coinName = coin
            sim.maxDiff = 260
            minute = Minute(data)
            if sim.play(minute) == 1:
                print "\nBET BET BET BET {}\n".format(coin)
        except Exception:
            traceback.print_exc()
            pass


