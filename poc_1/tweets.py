import os
import datetime
import zlib
import time
import sys
import traceback
import json
import mysql.connector 
from mail import sendMail
from tweepy import Stream
from tweepy import OAuthHandler
from tweepy.streaming import StreamListener
from pygments import highlight, lexers, formatters
import threading

KEYWORDS=[
    'blockchain',
    'cryptocurrency',
    'altcoin', 
    '#ICO'
    ]

def getCoinList():
    with open('coinlist.json', 'r') as f:
        coins = json.loads(f.read())['Data']
    return [x.replace("*", "") for x in coins if not "@" in x and not "." in x]

def prj(s):
    try:
        res = json.dumps(s, indent = 2)
        chien = highlight(unicode(res, 'UTF-8'), lexers.JsonLexer(), formatters.TerminalFormatter())
        print chien
    except:
        traceback.print_exc()
        pass
        #print(s)

def addlog(content):
    final = str(datetime.datetime.now().strftime("%d-%m-%Y %H:%M"))+"\n"
    with open ('/var/www/html/cryptolog.txt', 'a') as f:
        f.write(final + content + "\n\n")

class Listener(StreamListener):
    callBack = None
    def on_data(self, data):
        return self.callBack(data)
	
    def on_error(self, status):
		print(status)

class Main:
    def statTweet(self, tweet, id):
        for coin in self.coinList:
            if "$"+coin+'"' in tweet or "#"+coin+'"' in tweet:
                print coin
                self.cursor.execute('INSERT IGNORE INTO '+ coin + '_TW (id, time, sql_id) VALUE ('+str(id)+', '+str(time.time())+', 0);')
                self.conn.commit()

    def on_data(self, data):
        res = json.loads(data)
        id = res["id"]
        self.cursor.execute(""" INSERT IGNORE INTO tweets (id, data, time) VALUES (""" + str(id) + """ ,COMPRESS(%s), """+ str(time.time()) +""" ) """, (data,))
        self.conn.commit()
        self.statTweet(data, id)
        return True

    def __init__(self):
        self.coinList = getCoinList()
        self.conn = mysql.connector.connect(host="localhost",user="root",password="", database="crypto")
        self.cursor = self.conn.cursor()
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS tweets (
                id          BIGINT NOT NULL,
                time        INT NOT NULL,
                data        VARBINARY(5000),
                PRIMARY KEY(id)
            );
        """)
        self.listener = Listener()
        self.listener.callBack = self.on_data
        self.auth = OAuthHandler(ckey, csecret)
        self.auth.set_access_token(atoken, asecret)
        self.twitterStream = Stream(self.auth, self.listener)
        self.twitterStream.filter(track=KEYWORDS)

lastErr = 0
while True:
    try:
        Main()
    except:
        ex = traceback.format_exc()
        print ex
        if time.time() - lastErr < 5:
            sendMail("Crypto Tweet Exited", "Error")
            os._exit(0)
        lastErr = time.time()
        sendMail("Crypto Tweets Error", ex)
        addlog(ex)
        time.sleep(10)
