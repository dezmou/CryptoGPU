const fetch = require("node-fetch");
const crypto = require("crypto-js");
const struct = require('python-struct');
const fs = require("fs");

const OPEN_TIME = 0;
const OPEN = 1;
const HIGH = 2;
const LOW = 3;
const CLOSE = 4;
const VOLUME = 5;

const key = "s5PVpvenSY6UC7z5rYYy2dcDbbsWhPAgWl9oTkXygUyBEdsuXpFkyUcY9L8ifrKh";
const secret = require("./secret");
const apiUrl = "https://fapi.binance.com";

class Bot {
    constructor() {
        this.init()
    }

    async init() {
        this.getCandles()
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

    async getCandles() {
        const candles = (await this.apiRequest("klines", { symbol: "BTCUSDT", interval: "1m", limit: 500 }, "GET"))
        await this.saveCandlesBinary(candles)
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