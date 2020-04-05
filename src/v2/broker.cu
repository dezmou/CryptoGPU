#include "trade.h"

#define FEE_TAKER 0.0002
#define FEE_MAKER 0.0004

Broker newBroker(Data data) {
    Broker broker;
    broker.cursor = 0;
    broker.minutes = data.minutes;
    broker.nbrMinutes = data.nbrMinutes;
    broker.bank = 0;
    broker.seed = plantSeed();
    broker.bet.type = NO_BET;
    broker.bet.closeDown = 0;
    broker.bet.closeUp = 0;
    return broker;
}

#define MINUTE broker->minutes[broker->cursor]
#define SIZE_BET 100

__host__ __device__ static void closeBet(Bet *bet, int isWin) {
    bet->type = NO_BET;
#ifdef PLAY
    printf("%4s\n", (isWin == 1 ? "WIN" : "LOSE"));
#endif
}

__host__ __device__ void tickBroker(Broker *broker) {
    if (broker->bet.type == NO_BET) {
        broker->bet = analyse(&MINUTE, &broker->seed);
        if (broker->bet.type != NO_BET) {
            broker->bet.bank = -(SIZE_BET / MINUTE.close);
            double fee = SIZE_BET * FEE_TAKER;
            broker->bet.bank += -fee;
            broker->bet.totalFee = fee;
            // printMinute(&MINUTE);
        }
        return;
    } else if (broker->bet.type == SELL) {
        if (MINUTE.low < broker->bet.closeDown) {
            // WIN
            // printMinute(&MINUTE);
            // printf("HIGH : %lf CLOSE UP :%lf\n\n", MINUTE.high, broker->bet.closeUp);
            closeBet(&broker->bet, 1);
        } else if (MINUTE.high >= broker->bet.closeUp) {
            // LOSE
            // printMinute(&MINUTE);
            // printf("HIGH : %lf CLOSE UP :%lf\n\n", MINUTE.high, broker->bet.closeUp);
            closeBet(&broker->bet, 0);
        }
    } else if (broker->bet.type == BUY) {
        if (MINUTE.high > broker->bet.closeUp) {
            // WIN
            closeBet(&broker->bet, 1);
        } else if (MINUTE.low <= broker->bet.closeDown) {
            // LOSE
            closeBet(&broker->bet, 0);
        }
    }
}
