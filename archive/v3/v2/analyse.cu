#include "trade.h"

Seed plantSeed() {
    Seed seedRes;
    Seed *seed = &seedRes;
#define S_MIN_DIFF seed->a
    S_MIN_DIFF = randfrom(0.01, 3);
#define S_STOP_H seed->b
    S_STOP_H = randfrom(1.001, 1.03);
#define S_STOP_L seed->c
    S_STOP_L = randfrom(0.97, 0.99999);

    return seedRes;
}

DEVICE void static initBet(Bet *bet, int type, double price, double closeUp,
                           double closeDown) {
    bet->type = type;
    bet->closeUp = price + (price * (closeUp / 100));
    bet->closeDown = price - (price * (closeDown / 100));
}

DEVICE double change(double value1, double value2) {
    printf("%lf %lf %lf\n", value1, value2, 100 - (value1 / value2 * 100));
    return 100 - (value1 / value2 * 100);
}

DEVICE void analyse(Minute *minute, Seed *seed, Bet *bet) {
    bet->type = NO_BET;
    if (
        change(minute[-3].open, minute[0].close) < -1.3 
    
    ) {
            initBet(bet, SELL, minute[0].close, 1.5, 1);
    }
}
