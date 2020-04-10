#include "trade.h"

Seed plantSeed() {
    Seed seedRes;
    Seed *seed = &seedRes;
#define S_CURSOR_BACK seed->a
    S_CURSOR_BACK = randfrom(300, 10);
#define S_BACK_MAX seed->b
    S_BACK_MAX = randfrom(5, 50);
#define S_BACK_MIN seed->c
    S_BACK_MIN = randfrom(-5, -50);
#define S_CHANGE_ACT_MIN seed->d
    S_CHANGE_ACT_MIN = randfrom(-0.5, 0.5);
#define S_CHANGE_LAST_MIN seed->e
    S_CHANGE_LAST_MIN = randfrom(0.1, 4);
#define S_STOP_HIGH seed->f
    S_STOP_HIGH = randfrom(0.001, 0.2);
#define S_STOP_LOW seed->f
    S_STOP_LOW = randfrom(0.001, 0.2);

    // S_BACK_MAX = 20;
    // S_BACK_MIN = -10;
    // S_CURSOR_BACK = 400;
    // S_CHANGE_ACT_MIN = 2;
    // S_CHANGE_LAST_MIN = 3;
    return seedRes;
}

DEVICE void static initBet(Bet *bet, int type, double closeUp,
                           double closeDown) {
    bet->type = type;
    bet->closeUp = closeUp;
    bet->closeDown = closeDown;
}

DEVICE void analyse(Minute *minute, Seed *seed, Bet *bet) {
    bet->type = NO_BET;
    double allChange = 0;
    double allChangeNbr = 0;
    double backMin = 99999999;
    double backMax = -99999999;
    for (int i = -S_CURSOR_BACK; i < -6; i+=5) {
        allChange += fabs(100 - (minute[i].open / minute[i].close * 100));
        allChangeNbr += 1;
        if (minute[i].close > backMax) {
            backMax = minute[i].close;
        }
        if (minute[i].close < backMin) {
            backMin = minute[i].close;
        }
    }
    double variance = allChange / allChangeNbr;
    backMax = (100 - (minute->close / backMax * 100)) / variance;
    backMin = (100 - (minute->close / backMin * 100)) / variance;
    if (backMax < S_BACK_MAX && backMin > S_BACK_MIN) {
        double changeAct = 100 - (minute->open / minute->close * 100);
        double changeLast = 100 - (minute[-1].open / minute[0].close * 100);
        double changeActVar = changeAct / variance;
        double changeLastVar = changeLast / variance;
        if (changeLastVar > S_CHANGE_LAST_MIN && changeAct > 0) {
            // printf("VA: %-8.3lf BACKMAX: %-8.3lf BACKMIN: %-8.3lf\n", variance,
            //        backMax, backMin);
            initBet(bet, SELL, minute->close + (minute->close * variance * S_STOP_HIGH), minute->close - (minute->close * variance * S_STOP_LOW));
        }
    }
}
