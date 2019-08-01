TIME = 0
CURSOR = 1
COIN = 2
PRED = 3
REAL = 4

AMOUNT_BET = 100

CBLACK = "\33[30m"
CRED = "\33[31m"
CGREEN = "\33[32m"
CWHITE = "\33[37m"


with open("result", "r") as f:
    lines = f.readlines()

datas = []
for line in lines:
    sp = line.split("|")[:-1]
    neoLine = []
    if len(sp) > 0:
        for i,data in enumerate(sp):
            neoLine.append(data.split(":")[1])
    datas.append(neoLine)

coins = [{"id" : x, "won" : 0, "los" : 0} for x in range(1,163)]
bank = 0

totalBet = 0
for line in datas:
    if line:
        pred = float(line[PRED])
        real = float(line[REAL])
        coin = int(line[COIN])
        net = AMOUNT_BET * abs(real) * 0.01
        # if (abs(pred) > 0.4):
        if (True):
            totalBet += 1
            bank += -(0.002 * AMOUNT_BET)
            if (pred * real > 0):
                coins[coin+1]['won'] += 1
                win = True
                bank += net
            else:
                coins[coin+1]['los'] += 1
                win = False
                bank += -net
            perBet = totalBet / bank
            print "{} total {} : pred : {:12} real :{:12} bank :{:10.6} : Per-bet :{:.5}".format(CGREEN if win else CRED ,totalBet, pred, real, bank, perBet)
coins = sorted(coins, key=lambda x : x["won"] - x["los"])

for coin in coins:
    if (coin['los'] + coin['won'] > 1):
        print coin
