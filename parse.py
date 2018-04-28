import traceback
import mysql.connector 
import json
import urllib2
from mail import sendMail
import time
import datetime

TIME_IDLE = 60 * 60 * 4

def addlog(content):
    final = str(datetime.datetime.now().strftime("%d-%m-%Y %H:%M"))+"\n"
    with open ('/var/www/html/cryptolog.txt', 'a') as f:
        f.write(final + content + "\n\n")

class Parser:
    def __init__(self):
        while True:
            try:
                self.conn = mysql.connector.connect(host="localhost",user="root",password="", database="crypto")
                self.cursor = self.conn.cursor()
                self.loadCoinList()
                self.getAllPrices()
                self.cursor.close()
                addlog("Succes !")
            except:
                ex = traceback.format_exc()
                addlog(ex)
                sendMail("Crypto Parsing Error", ex)
            time.sleep(TIME_IDLE)

    def insertDB(self, data, coin):
        coin = coin.replace("*", "")
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS """ + coin + """_BTC (
                time        INT NOT NULL,
                volumefrom  DOUBLE NOT NULL,
                volumeto    DOUBLE NOT NULL,
                high        DOUBLE NOT NULL,
                low         DOUBLE NOT NULL,
                close       DOUBLE NOT NULL,
                open        DOUBLE NOT NULL,
                PRIMARY KEY(time)
            );
        """)
        for price in data:
            query = """
                INSERT IGNORE INTO {}(time, volumefrom, volumeto, high, low, close, open) VALUES({}, {}, {}, {}, {}, {} , {});
            """.format(coin+"_BTC", price['time'], price['volumefrom'], price['volumeto'], price['high'], price['low'], price['close'], price['open'])
            self.cursor.execute(query)
        self.conn.commit()

    def getPrices(self, coin):
        contents = urllib2.urlopen("https://min-api.cryptocompare.com/data/histominute?fsym="+coin+"&tsym=BTC&limit=2000").read()
        if contents[:40] != '{"Response":"Success","Type":100,"Aggreg':
            return
        data = json.loads(contents)['Data']
        self.insertDB(data, coin)

    def getAllPrices(self):
        for i,coin in enumerate(self.coins):
            if "@" in coin:
                continue
            print str(i) + " " + coin
            self.getPrices(coin)
            # break

    def loadCoinList(self):
        with open("coinlist.json", "r") as f:
            self.coins = json.loads(f.read())['Data']
                
if __name__ == "__main__":
    addlog("Started")
    Parser()
