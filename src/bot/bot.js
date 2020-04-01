const fetch = require("node-fetch");
const crypto = require("crypto-js");
const struct = require('python-struct');
const fs = require("fs");
const exec = require('child_process').exec;

const OPEN_TIME = 0;
const OPEN = 1;
const HIGH = 2;
const LOW = 3;
const CLOSE = 4;
const VOLUME = 5;

const NO_BET = 0;
const BUY = 1;
const SELL = 2;

const key = "s5PVpvenSY6UC7z5rYYy2dcDbbsWhPAgWl9oTkXygUyBEdsuXpFkyUcY9L8ifrKh";
const secret = require("./secret");
const apiUrl = "https://fapi.binance.com";

class Bot {
    constructor() {
        this.lastMinute = 0;
        this.init()
    }

    async init() {
        while (true) {
            const candles = await this.waitNewMinute();
            await this.saveCandlesBinary(candles)
            const analyst = await this.analyse();
            console.log(analyst);
        }
    }

    async saveCandlesBinary(candles) {
        // return list(struct.iter_unpack("qddddd", fd[coinName].read(size * 6 * 8)))
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

    async analyse() {
        const out = await new Promise(resolve => {
            exec("../sim/bot ./binance", (error, stdout, stderr) => {
                resolve(stdout);
            });
        })
        console.log(out);
        const res = out.split("\n").find(e => e.indexOf("BET;") !== -1).split(";")
        return {
            bet: ['no', 'buy', 'sell'][res[1]],
            close_win: res[2],
            close_lose: res[3]
        }
    }

    async waitNewMinute() {
        while (true) {
            const res = await this.getCandles()
            if (this.lastMinute !== res[res.length - 2][OPEN_TIME]) {
                this.lastMinute = res[res.length - 2][OPEN_TIME];
                return res;
            }
            await new Promise(resolve => setTimeout(resolve, 1000));
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

new Bot()