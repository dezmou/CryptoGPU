#include "trade.h"

#define BET_AMOUNT 10000

double getVariance(Minute *minute, Potards *potards) {
    double min = 99999999999;
    double max = -9999999999;
    for (int cursor = -(potards->period_for_variance + 1); cursor <= 0;
         cursor++) {
        if (minute[cursor].low < min) {
            min = minute[cursor].low;
        }
        if (minute[cursor].high > max) {
            max = minute[cursor].high;
        }
    }
    return (max / min * 100) - 100;
}

Bet newBet() {
    Bet bet;
    bet.type = NO_BET;
    bet.totalFee = 0;
    bet.amount = 0.015;
    return bet;
}

Bet analyse(Minute *minute, Potards *potards) {
    Bet bet = newBet();
    // getchar();
    double change_before_long =
        100 - (minute[-(potards->change_before_long_steps)].close /
               minute->close * 100);
    // printf("%lf %lf %lf\n",minute[-2].close,minute->close
    // ,change_before_long); getchar();
    double variance = getVariance(minute, potards);

    if (change_before_long > potards->change_before_long &&
        variance < potards->maxVariance) {
        bet.amount = BET_AMOUNT / minute->close;

        bet.type = SELL;
        bet.closeLose = minute->close *
                        (1 + (potards->closeLose * change_before_long) * 0.01);
        bet.closeWin = minute->close *
                       (1 - (potards->closeWin * change_before_long) * 0.01);

        // bet.type = BUY;
        // bet.closeLose = minute->close * (1 - 0.01);
        // bet.closeWin = minute->close * (1 + 0.01);
    }
    return bet;
}
