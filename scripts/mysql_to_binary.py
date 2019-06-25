# Parse Data from Mysql and create Unique Binary file 

import os
import pymysql
import struct

ID = 0
DATE = 1
OPEN = 2
HIGH = 3
LOW = 4
CLOSE = 5
VOLUME = 6

db = pymysql.connect("localhost", "dez", os.environ['PASS'], "trade")
cursor = db.cursor()

cursor.execute("SELECT * FROM time  ORDER BY time ASC ;")
res = cursor.fetchall()
totalLine = 0
with open("../data/bin/full", "wb") as f:
    for line in res:
        totalLine += 1
        time = line[0]
        cursor.execute("SELECT * FROM coin_price WHERE time = {} ORDER BY coin_name_id ASC;".format(time))
        coins = cursor.fetchall()
        nbrCoins = len(coins)
        indexCoin = 0
        binaryLine = struct.pack('l', time)
        for indexId in range(1,163):
            if indexCoin < nbrCoins:
                coin = coins[indexCoin]
            if coin[ID] == indexId and indexCoin < nbrCoins:
                indexCoin += 1
                content = [coin[OPEN],coin[HIGH],coin[LOW],coin[CLOSE],coin[VOLUME]]
            else:
                content = [-1,-1,-1,-1,-1]
            for value in content:
                binaryLine += struct.pack('d', float(value))
            # print ("{} {} {} ".format(time, indexId, content))
        if (totalLine % 100) == 0:
            print("{} / 881003".format(totalLine))
        f.write(binaryLine)
        # break