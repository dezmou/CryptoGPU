#include "trade.h"

Seed plantSeed() {
    Seed seedRes;
    Seed *seed = &seedRes;
#define S_CURSOR_BACK seed->a
    S_CURSOR_BACK = randfrom(400, 10);


    S_CURSOR_BACK = 400;
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
    for (int i = -S_CURSOR_BACK; i < 0; i++) {
        allChange += fabs(100 - (minute[i].open / minute[i].close * 100));
        allChangeNbr += 1;
        // if 
    }
    double variance = allChange / allChangeNbr;
    // printf("\nVA: %-8.3lf\n", variance);
    initBet(bet, SELL, minute->close * 1.001, minute->close * 0.999);
}
