import random

ACTION_BUY = 0
ACTION_SELL = 1

colors = [
'\33[37m',
'\33[31m',
'\33[32m',
'\33[33m',
'\33[34m',
'\33[35m',
'\33[36m',
'\33[30m',

]

def strColor(string):
    res = ""
    for i, data in enumerate(string.split("|")):
        res += colors[i]+" " + data
    return res
    

class Simulator:
    rake = 0.001
    # rake = 0.000
    totalRake = 0
    nbrPlay = 0
    def __init__(self):
        self.bank = 0

    def trade(self,amount, action, stepClose):
        realEnd = self.minute.real.prices[stepClose]
        if (realEnd > 100): return 0
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
                if price < 0: down += 1
                if price > 0: up += 1
        diff = up - down 
        if (diff < 80):
            res = self.trade(1000,ACTION_BUY if diff > 0 else ACTION_SELL,5)
            self.bank += res
            self.nbrPlay += 1
            print(strColor("Play : {:7}| up : {:4}| down : {:4}| diff : {:4}| bank : {:15}| rake : {:15}").format(self.nbrPlay, up, down, diff, self.bank, self.totalRake))
        return 0

    def play(self, minute):
        self.minute = minute
        self.engine()
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

class Main:
    def __init__(self):
        with open("result", "r") as f:
            lines = f.readlines()
        minutes = []
        sim = Simulator()
        for line in lines:
            minute = Minute(line)
            minutes.append(minutes)
            sim.play(minute)
            # break
        
Main()