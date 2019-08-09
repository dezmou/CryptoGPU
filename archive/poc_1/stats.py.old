import os
import time
import mysql.connector 
import json

MIN_SCORE   = 50
NBR_TOP_SCORE = 7
HOUR        = 3600
INT32_MAX   = 2147483647
TIME_REFRESH = 60 * 60

def getCoinList():
    with open('coinlist.json', 'r') as f:
        coins = json.loads(f.read())['Data']
    return [x.replace("*", "") for x in coins if not "@" in x and not "." in x]

class Stats:
    
    def getFirstTweet(self, coin):
        self.cursor.execute('SELECT * FROM {}_TW LIMIT 1;'.format(coin))
        return self.cursor.fetchone()

    def getGraph(self,coin):
        if self.start == 0:
            start = self.getFirstTweet(coin)[1]
        else:
            start = self.start
        endSlice = start + self.interval
        ret = []
        while endSlice <= self.end:
            res = self.getScore(coin, start=start, end = endSlice)
            #  print "{} ~~~> {}".format(time.ctime(endSlice), res)
            ret.append({'time' : endSlice, 'pop' : res})
            endSlice += self.interval
            start += self.interval
        return ret

    def getScore(self,coin, start = time.time() - HOUR, end = INT32_MAX):
        self.cursor.execute('SELECT COUNT(id) FROM {}_TW WHERE time >= {} AND time <= {};'.format(coin, start, end))
        return self.cursor.fetchone()[0]

    def getTopScores(self, limit = NBR_TOP_SCORE):
        chien = []
        for coin in self.coins:
            chien.append({"name": coin, "pop" : self.getScore(coin)})
        return sorted(chien, key= lambda x:x['pop'], reverse = True)[:limit]

    def genTweets(self, coin):
        print coin
        self.cursor.execute('SELECT id FROM {}_TW;'.format(coin))
        res = [x[0] for x in self.cursor.fetchall()]
        for id in res:
            self.cursor.execute('SELECT UNCOMPRESS(data) FROM tweets WHERE id={};'.format(id))
            yield json.loads(self.cursor.fetchone()[0].decode("utf8")) 

    def getResume(self):
        self.coins = getCoinList()
        # self.getGraph('TRX')        
        self.top =  self.getTopScores()
        for i,coin in enumerate(self.top):
            self.top[i]['graph'] = self.getGraph(coin['name'])
            print "{:12} {}".format(self.top[i]['name'], self.top[i]['pop'])
        with open("/var/www/html/graph.json", 'w') as f:
            f.write(json.dumps(self.top, indent=2))

    def __init__(self, start = 0, end = time.time(), interval = HOUR):
        self.start = start
        self.end = end
        self.interval = interval
        self.conn = mysql.connector.connect(host="localhost",user="root",password="", database="crypto")
        self.cursor = self.conn.cursor()
            
while True:
    try:
        s = Stats()
        s.getResume()
        time.sleep(TIME_REFRESH)
    except:
        time.sleep(100)

