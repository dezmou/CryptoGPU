const fetch = require("node-fetch");
const crypto = require("crypto-js");
const struct = require('python-struct');
const fs = require("fs");
const exec = require('child_process').exec;
const secrets = require("./secret");
const notif = require("./notif");

const OPEN_TIME = 0;
const OPEN = 1;
const HIGH = 2;
const LOW = 3;
const CLOSE = 4;
const VOLUME = 5;

const NO_BET = 0;
const BUY = 1;
const SELL = 2;

const key = secrets.binance_key;
const secret = secrets.binance_secret;
const apiUrl = "https://fapi.binance.com";

class Bot {
    constructor() {
        this.lastMinute = 0;
        // this.betBinance()
        this.init()
    }

    async betBinance(bet, candles) {
        const sumary = {}
        bet.close_win = Number.parseFloat(bet.close_win).toFixed(2);
        bet.close_lose = Number.parseFloat(bet.close_lose).toFixed(2);

        const amount = 0.01;

        const [
            openOrder,
            winOrder,
            loseOrder
        ] = await Promise.all([
            this.apiRequest('order', {
                symbol: "BTCUSDT",
                side: 'SELL',
                type: "MARKET",
                quantity: amount
            }, 'POST'),
            this.apiRequest('order', {
                symbol: "BTCUSDT",
                side: 'BUY',
                type: "LIMIT",
                price: bet.close_win,
                quantity: amount,
                timeInForce: 'GTC'
            }, 'POST'),
            this.apiRequest('order', {
                symbol: "BTCUSDT",
                side: 'BUY',
                type: "STOP_MARKET",
                stopPrice: bet.close_lose,
                quantity: amount
            }, 'POST')
        ])

        // console.log(openOrder);
        // console.log(loseOrder);

        const openOrderRes = await this.apiRequest('order', {
            symbol: "BTCUSDT",
            orderId: openOrder.orderId
        }, 'GET')
        sumary.openTarget = candles[candles.length - 2][CLOSE];
        sumary.openFilled = openOrderRes.avgPrice

        // notif("Bet SELL", `Target : ${sumary.openTarget}\n Filled : ${sumary.openFilled}`);
        // console.log(sumary);
        while (true) {
            const allOrders = await this.apiRequest('openOrders', {
                symbol: "BTCUSDT",
            }, 'GET')
            if (allOrders.length === 0) {
                break;
            }
            if (allOrders.length !== 2) {
                await this.apiRequest('allOpenOrders', {
                    symbol: "BTCUSDT",
                }, 'DELETE')
            }
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        const tradeHistory = await this.apiRequest('allOrders', {
            symbol: "BTCUSDT",
            orderId: openOrder.orderId
        }, 'GET')
        const resWin = tradeHistory.find(e => e.orderId === winOrder.orderId);
        const resLose = tradeHistory.find(e => e.orderId === loseOrder.orderId);
        if (resWin.status === 'FILLED') {
            sumary.won = true;
            sumary.closeTarget = bet.close_win;
            sumary.closeFilled = resWin.avgPrice;
            notif("WON", `Target : ${bet.close_win}\n Filled : ${resWin.avgPrice}`);
        } else {
            sumary.won = false;
            sumary.closeTarget = bet.close_lose;
            sumary.closeFilled = resLose.avgPrice;
            notif("LOST", `Target : ${bet.close_lose}\n Filled : ${resLose.avgPrice}`);
        }
        console.log(sumary);
        this.lastMinute = 0;
    }

    async init() {
        while (true) {
            const candles = await this.waitNewMinute();
            const bet = await this.analyse(candles);
            if (bet.type !== "no") {
                await this.betBinance(bet, candles);
            }
        }
    }

    async saveCandlesBinary(candles) {
        const binaryLines = []
        for (let candle of candles) {
            const res = struct.pack(`qddddd`, [candle[OPEN_TIME] / 1000, candle[OPEN], candle[HIGH], candle[LOW], candle[CLOSE], candle[VOLUME]]);
            binaryLines.push(res)
        }
        binaryLines.pop();
        await new Promise(resolve => {
            fs.writeFile("binance", Buffer.concat(binaryLines), "binary", resolve);
        })
    }

    async analyse(candles) {
        await this.saveCandlesBinary(candles)
        const out = await new Promise(resolve => {
            exec("../sim/bot ./binance", (error, stdout, stderr) => {
                resolve(stdout);
            });
        })
        console.log(out);
        const res = out.split("\n").find(e => e.indexOf("BET;") !== -1).split(";")
        return {
            type: ['no', 'buy', 'sell'][res[1]],
            close_win: res[2],
            close_lose: res[3]
        }
    }

    async waitNewMinute() {
        while (true) {
            const res = await this.getCandles()
            if (this.lastMinute !== res[res.length - 2][OPEN_TIME]) {
                if (this.lastMinute === 0) {
                    this.lastMinute = res[res.length - 2][OPEN_TIME];
                } else {
                    this.lastMinute = res[res.length - 2][OPEN_TIME];
                    return res;
                }
            }
            await new Promise(resolve => setTimeout(resolve, 600));
        }
    }

    async getCandles() {
        const candles = (await this.apiRequest("klines", { symbol: "BTCUSDT", interval: "1m", limit: 500 }, "GET"))
        return candles;
    }

    async apiRequest(endPoint, params, method) {
        let paramsStr = ''
        for (let param of Object.entries(params)) {
            paramsStr += `${param[0]}=${param[1]}&`
        }
        paramsStr += `timestamp=${Date.now()}`
        paramsStr += `&signature=${crypto.HmacSHA256(paramsStr, secret).toString(crypto.enc.Hex)}`;
        const res = await fetch(`${apiUrl}/fapi/v1/${endPoint}?${paramsStr}`, {
            headers: {
                "X-MBX-APIKEY": key
            },
            method,
        });
        // console.log(res.headers);
        return await res.json();
    }
}
try {
    new Bot()

} catch (error) {
    notif("ERROR", error);
}