#include "trade.h"

__host__ __device__ void static initBet(Bet *bet, int type, double closeUp,
                                double closeDown) {
    bet->type = type;
    bet->closeUp = closeUp;
    bet->closeDown = closeDown;
}

__host__ __device__ Bet analyse(Minute *minute, Seed *seed) {
    Bet bet;
    initBet(&bet, SELL, minute->close * 1.05, minute->close * 0.95);
    return bet;
}