# Take data from the internet in many CSV files from binance history and give it to mysql

import datetime
import os
from os import listdir
from os.path import isfile, join
import pymysql
import warnings

DATE = 0
OPEN = 1
HIGH = 2
LOW = 3
CLOSE = 4
VOLUME = 5


db = pymysql.connect("localhost", "dez", os.environ['PASS'], "trade")
cursor = db.cursor()

# DATA_PATH = "../data/raw"
# cursor.execute("""
# CREATE TABLE IF NOT EXISTS `trade`.`coin_name` (
#   `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
#   `name` VARCHAR(45) NULL,
#   PRIMARY KEY (`id`),
#   UNIQUE INDEX `name_UNIQUE` (`name` ASC));
# """)

# curs = [f.replace(".csv", "")
#         for f in listdir(DATA_PATH) if isfile(join(DATA_PATH, f))]
# for cur in curs:
#     print(cur)
#     cursor.execute("INSERT INTO coin_name (name) VALUES ('{}')".format(cur))
# db.commit()


cursor.execute("SELECT * FROM coin_name ORDER BY id ASC")
res = cursor.fetchall()
for coin in res:
    print(coin)
    if coin[0] < 123: continue
    with open("../data/raw/{}.csv".format(coin[1]), "r") as f:
        lines = f.read().split("\n")[:-1][1:]
    lastStamp = 0
    nbrProced = 0
    for line in lines:
        try:
            nbrProced += 1
            sp = line.split(",")
            date = sp[DATE][:-10]
            stamp = int(datetime.datetime.strptime(
                date, "%Y-%m-%d %H:%M").timestamp())
            if lastStamp == stamp:
                continue
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                cursor.execute("INSERT IGNORE INTO coin_price (coin_name_id, time, open, high, low, close, volume) VALUES ({}, {}, {}, {} ,{}, {}, {})".format(
                    coin[0], stamp, sp[OPEN], sp[HIGH], sp[LOW], sp[CLOSE], sp[VOLUME]))
                cursor.execute("INSERT IGNORE INTO time (time) VALUE ({})".format(stamp))
                if nbrProced % 100 == 0:
                    db.commit()
            lastStamp = stamp
        except Exception as e: print (str(e))
    # break


# """list coins"""
# cursor.execute("SELECT * FROM coin_name ORDER BY id ASC")
# res = cursor.fetchall()
# for coin in res:
#     print(coin)
#     chien = cursor.execute("SELECT * FROM coin_price WHERE coin_name_id = {} LIMIT 1;".format(coin[0]))
#     print(cursor.fetchall())


db.close()
