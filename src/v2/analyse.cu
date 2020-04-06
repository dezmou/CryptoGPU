#include "trade.h"

Seed plantSeed() {
    Seed seed;
    seed.chien = randfrom(5, 14000);
    seed.a = randfrom(0.95, 0.9999);
    seed.b = randfrom(1.001, 1.1);
    seed.c = randfrom(0.95, 0.9999);
    return seed;
}

__host__ __device__ void static initBet(Bet *bet, int type, double closeUp,
                                        double closeDown) {
    bet->type = type;
    bet->closeUp = closeUp;
    bet->closeDown = closeDown;
}

__host__ __device__ Bet analyse(Minute *minute, Seed *seed) {
    Bet bet;
    bet.type = NO_BET;
    if (minute[-3].close / minute[0].close < seed->a) {
        initBet(&bet, SELL, minute->close * seed->b, minute->close * seed->c);
    }
    // if ((int)minute->close % 2 == 0) {
    //     initBet(&bet, SELL, minute->close * 1.01, minute->close * 0.99);
    // } else {
    //     initBet(&bet, BUY, minute->close * 1.05, minute->close * 0.95);
    // }
    return bet;
}