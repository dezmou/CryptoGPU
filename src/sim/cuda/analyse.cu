#include "trade.h"

#define BET_AMOUNT 10000

__device__ double getVariance(Minute *minute, Potards *potards) {
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

__device__ Bet newBet(Minute *minute, int type, double amount, double closeWin,
           double closeLose) {
    Bet bet;
    bet.type = type;
    bet.totalFee = 0;
    bet.amount = amount;
    bet.closeLose = 0;
    bet.closeWin = 0;
    if (bet.type == NO_BET) {
        return bet;
    } else if (bet.type == SELL) {
        bet.closeLose = minute->close * (1 + closeLose * 0.01);
        bet.closeWin = minute->close * (1 - closeWin * 0.01);
    } else if (bet.type == BUY) {
        bet.closeLose = minute->close * (1 - closeLose * 0.01);
        bet.closeWin = minute->close * (1 + closeWin * 0.01);
    }
    return bet;
}

__device__ Bet analyse(Minute *minute, Potards *potards) {
    // dev
    // return newBet(minute, SELL, BET_AMOUNT / minute->close,
    //               potards->closeWin ,
    //               potards->closeLose);

    double change_before_long =
        100 - (minute[-(potards->change_before_long_steps)].close /
               minute->close * 100);
    double variance = getVariance(minute, potards);
    if (change_before_long > potards->change_before_long &&
        variance < potards->maxVariance) {
        return newBet(minute, SELL, BET_AMOUNT / minute->close,
                      potards->closeWin * change_before_long,
                      potards->closeLose * change_before_long);
    } else {
        return newBet(NULL, NO_BET, 0, 0, 0);
    }
}