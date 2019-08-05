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
        if up > 310 and down < 150:
            # res = self.trade(1000,ACTION_BUY if diff > 0 else ACTION_SELL,self.stepClose)
            res = self.trade(1000,ACTION_BUY,self.stepClose)
            self.bank += res
            self.nbrPlay += 1
            print(strColor("{} Play : {:12}| up : {:12}| down : {:12}| diff : {:12}| won : {:15}| rake : {:15}| Perf : {:15}| Tend : {:15}").format(colors[2] if res > 0 else colors[1], self.nbrPlay, up, down, diff, self.bank, self.totalRake, self.bank / self.nbrPlay, self.fakeBank))
        self.nbrMinutes += 1
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
        sim.stepClose = 9
        sim.maxDiff = 260
        for line in lines:
            minute = Minute(line)
            minutes.append(minute)
            sim.play(minute)
            # break
        li = []

        # for step in range(4, 10):
        #     # for diff in [120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270]:
        #     for diff in [240, 250, 260, 270, 280, 290, 300, 310, 320]:
        #         sim = Simulator()
        #         sim.stepClose = step
        #         sim.maxDiff = diff
        #         for minute in minutes:
        #             sim.play(minute)
        #         li.append([sim.bank / sim.nbrPlay, "{:15}    {:14} {:5} {:5} {:5}".format(sim.bank/ sim.nbrPlay ,sim.bank, sim.stepClose, sim.maxDiff, sim.nbrPlay)])
        #         print "{:15}    {:14} {:5} {:5} {:5}".format(sim.bank/ sim.nbrPlay ,sim.bank, sim.stepClose, sim.maxDiff, sim.nbrPlay)
        # chien = sorted(li, key = lambda x : x[0])
        # print("\n\n")
        # for lapin in chien:
        #     print lapin[1]

        
Main()