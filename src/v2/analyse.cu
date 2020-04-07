#include "trade.h"

Seed plantSeed() {
    Seed seedRes;
    Seed *seed = &seedRes;
#define S_LONG_BACK seed->a
    S_LONG_BACK = randfrom(2, 5);
#define S_MIN_TREND_UP seed->b
    S_MIN_TREND_UP = randfrom(0.1, 0.9);
#define S_MIN_LONG_CHANGE seed->c
    S_MIN_LONG_CHANGE = randfrom(0.001, 0.1);
#define S_STOP_UP_X_CHANGE seed->d
    S_STOP_UP_X_CHANGE = randfrom(0.1, 2);
#define S_STOP_DOWN_X_CHANGE seed->e
    S_STOP_DOWN_X_CHANGE = randfrom(0.1, 2);

    return seedRes;
}

__host__ __device__ void static initBet(Bet *bet, int type, double closeUp,
                                        double closeDown) {
    bet->type = type;
    bet->closeUp = closeUp;
    bet->closeDown = closeDown;
}

__host__ __device__ void analyse(Minute *minute, Seed *seed, Bet *bet) {
    bet->type = NO_BET;

    // double totalChange
    double amountDown = 0;
    double amountUp = 0;
    for (int i = -((int)S_LONG_BACK); i < 0; i++) {
        if (minute[i].open < minute[i + 1].open) {
            amountUp += minute[i + 1].open / minute[i].open;
        } else if (minute[i].open > minute[i + 1].open) {
            amountDown += minute[i].open / minute[i + 1].open;
        }
    }
    double tendenceUp = (amountUp - amountDown) / (int)S_LONG_BACK;
    if (tendenceUp > S_MIN_TREND_UP) {
        double change = (minute->close / (minute[-(int)S_LONG_BACK].close)) - 1;
        if (change >= S_MIN_LONG_CHANGE) {

            // printf(
            //     "BAK : %-10.2lf CUR: %-10.2lf   UP: %-10.2lf DOW: %-10.2lf TD: "
            //     "%-10.2lf LB: %ld CH: %-4.4lf\n",
            //     minute[-(int)S_LONG_BACK].close, minute->close, amountUp,
            //     amountDown, tendenceUp, (long)S_LONG_BACK, change);

            initBet(
                bet, SELL,
                ((change * S_STOP_UP_X_CHANGE) * minute->close) + minute->close,
                ((change * S_STOP_DOWN_X_CHANGE) * -minute->close) +
                    minute->close);
        }

        // if (change >= S_MIN_LONG_CHANGE) {
        //     initBet(bet, SELL, minute->close * seed->b,
        //             minute->close * seed->c);
        // }
    }

    // // double up = minute[-S_LONG_BACK].close
    // // exit(0);
    // if (minute[-3].close / minute[0].close < seed->a) {
    //     initBet(bet, SELL, minute->close * seed->b, minute->close * seed->c);
    // }
    // // if ((int)minute->close % 2 == 0) {
    // //     initBet(&bet, SELL, minute->close * 1.01, minute->close * 0.99);
    // // } else {
    // //     initBet(&bet, BUY, minute->close * 1.05, minute->close * 0.95);
    // // }
    // // return bet;
}