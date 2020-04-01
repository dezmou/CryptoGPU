#include "trade.h"

Potards newPotards() {
    Potards res;
    res.change_before_long = 1.35;
    res.change_before_long_steps = 10;
    res.closeWin = 0.64;
    res.closeLose = 3.55;
    res.period_for_variance = 40;
    res.maxVariance = 17.11;
    return res;
}

void printBet(Bet bet) {
    // printf("BET %-5d, AMT: %-10lf, CLW: %-10lf, CLL: %-10lf\n", bet.type,
    //        bet.amount, bet.closeWin, bet.closeLose);
    printf("BET;%d;%lf;%lf\n", bet.type, bet.closeWin, bet.closeLose);
}

int main(int argc, char *argv[]) {
    Data data = loadMinutes(argv[1]);
    printf("%d\n", data.nbrMinutes);
    printMinute(&data.minutes[data.nbrMinutes - 1]);
    Potards potards = newPotards();
    Bet bet = analyse(&data.minutes[data.nbrMinutes - 1], &potards);
    printBet(bet);
    return 0;
}