const fetch = require("node-fetch");
const crypto = require("crypto-js");
const printf = require("printf");

const key = "s5PVpvenSY6UC7z5rYYy2dcDbbsWhPAgWl9oTkXygUyBEdsuXpFkyUcY9L8ifrKh";
const apiUrl = "https://fapi.binance.com";

const OPEN_TIME = 0;
const OPEN = 1;
const HIGH = 2;
const LOW = 3;
const CLOSE = 4;

const KNRM = "\x1B[0m";
const KRED = "\x1B[31m";
const KGRN = "\x1B[32m";
const KYEL = "\x1B[33m";
const KBLU = "\x1B[34m";
const KMAG = "\x1B[35m";
const KCYN = "\x1B[36m";
const KWHT = "\x1B[37m";


(async () => {
    try {
        const apiRequest = async (endPoint, params, method) => {
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

        const getPosition = async () => {
            const res = await apiRequest('positionRisk', {}, "GET")
            return res.find(e => e.symbol === "BTCUSDT")
        }

        const closePosition = async (size) => {
            let amount;
            if (size === undefined) {
                const position = await getPosition();
                amount = parseFloat(position.positionAmt);
            } else {
                amount = size;
            }
            console.log(size);
            if (Math.abs(amount) > 0) {
                const order = await apiRequest('order', {
                    symbol: "BTCUSDT",
                    side: amount < 0 ? "BUY" : "SELL",
                    type: "MARKET",
                    quantity: Math.abs(amount)
                }, 'POST')
                return order;
            }
            return {}
        }

        let lastMinute = 0;
        const nextMinute = async () => {
            while (true) {
                const res = (await apiRequest("klines", { symbol: "BTCUSDT", interval: "1m", limit: 2 }, "GET"))[0]
                if (res[OPEN_TIME] !== lastMinute) {
                    lastMinute = res[OPEN_TIME];
                    return res;
                }
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }

        // const changeRequired = 0.43;
        // const closeWin = 0.32;
        // const closeLoss = 0.96;
        // const maxWait = 57;

        // const changeRequired = 0.42;
        const changeRequired = 0.05;
        const closeWin = 4.03;
        const closeLoss = 0.10;
        const maxWait = 8;

        const betSize = 0.015;

        const bet = async (side) => {
            const resOrder = await apiRequest('order', {
                symbol: "BTCUSDT",
                side,
                type: "MARKET",
                quantity: betSize
            }, 'POST')
            let diff;
            let i = 0;
            const betRes = await (async () => {
                const startTime = Date.now();
                while (true) {
                    const res = (await apiRequest('positionRisk', {}, "GET")).find(e => e.symbol === "BTCUSDT")
                    diff = ((res.markPrice - res.entryPrice) / res.entryPrice) * 100;
                    if (side === "BUY") {
                        if (diff >= closeWin) {
                            return { result: "win", diff: Math.abs(diff) }
                        } else if (diff < -closeLoss) {
                            return { result: "lose", diff: Math.abs(diff) }
                        }
                    } else if (side === "SELL") {
                        if (diff <= -closeWin) {
                            return { result: "win", diff: Math.abs(diff) }
                        } else if (diff > closeLoss) {
                            return { result: "lose", diff: Math.abs(diff) }
                        }
                    }
                    const waited = (Date.now() - startTime) / 1000 / 60
                    if (i % 10 === 0) {
                        // console.log(waited, side, res.entryPrice, res.markPrice, diff);
                    }
                    if (waited > maxWait) {
                        if (side === "BUY") {
                            if (diff >= 0) {
                                return { result: "win", diff: Math.abs(diff) }
                            } else if (diff < -0) {
                                return { result: "lose", diff: Math.abs(diff) }
                            }
                        } else if (side === "SELL") {
                            if (diff <= -0) {
                                return { result: "win", diff: Math.abs(diff) }
                            } else if (diff > 0) {
                                return { result: "lose", diff: Math.abs(diff) }
                            }
                        }
                    }
                    i++;
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
            })()
            console.log(betRes);
            await closePosition(side === "BUY" ? betSize : -betSize);
            return diff;
        }

        const analyse = async (minute) => {
            const change = 100 - ((minute[OPEN] / minute[CLOSE]) * 100);
            // console.log(minute[OPEN], minute[CLOSE], change);
            if (Math.abs(change) > changeRequired) {
                await bet(change < 0 ? "BUY" : "SELL")
            }
        }
        // printf("")
        console.log("start");
        while (true) {
            try {
                const res = await nextMinute()
                await analyse(res)
            } catch (error) {
                await new Promise(resolve => setTimeout(resolve, 1000));
                console.log(Date.now(), error);
            }
            // console.log(res);
        }

    } catch (error) {
        console.log(error);
    }
})()

// 01 58 99 29 38

// 139.19