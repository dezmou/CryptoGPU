#include "trade.h"

// 0.517219 0.178939 1.065050 0.987929 1.234249 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// 0.849640 0.001358 1.068678 0.962473 1.121986 0.000000 0.000000 0.000000 1.190795 0.000000 0.242834 0.000000 0.000000 0.000000 0.990490 0.000000
// 0.370637 0.147151 1.054269 0.981191 0.868640 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000

// 2%
// 0.478204 0.004966 1.052160 0.981566 0.581564 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000

// 0.332915 0.155089 1.114306 0.988472 0.874413 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// BK: 1.66     FEE: 0.35     NB: 567   REG: 95.238

// 0.349157 0.144118 1.114791 0.988247 0.907242 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// BK: 1.68     FEE: 0.34     NB: 560   REG: 100.000

// 0.370161 0.113735 1.021199 0.964752 1.128213 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// BK: 1.84     FEE: 0.52     NB: 725   REG: 100.000

// 0.343292 0.178984 1.039019 0.980172 0.702511 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// BK: 1.84     FEE: 0.35     NB: 538   REG: 104.762

// 0.347328 0.025025 1.053060 0.979931 0.559451 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
// BK: 1.88     FEE: 0.45     NB: 703   REG: 100.000

Seed plantSeed() {
    Seed seedRes;
    Seed *seed = &seedRes;
#define S_MIN_FIRST_CHANGE seed->a
    S_MIN_FIRST_CHANGE = randfrom(0.3, 6);
#define S_MIN_LAST_CHANGE seed->b
    S_MIN_LAST_CHANGE = randfrom(-1, 3);
#define S_TOP_HIGH seed->c
    S_TOP_HIGH = randfrom(1.001, 1.2);
#define S_STOP_LOW seed->d
    S_STOP_LOW = randfrom(0.95, 0.999);
#define S_FIRST_CHANGE_SIZE seed->e
    S_FIRST_CHANGE_SIZE = randfrom(0.50, 2);

    // S_MIN_FIRST_CHANGE = randfrom(0.50, 0.52);
    // S_MIN_LAST_CHANGE = randfrom(1.15, 0.17);
    // S_TOP_HIGH = randfrom(1.05, 1.07);
    // S_STOP_LOW = randfrom(0.975, 0.999);


    // S_MIN_FIRST_CHANGE = randfrom(0.75, 1);
    // S_MIN_LAST_CHANGE = randfrom(0.0001, 0.003);
    // S_TOP_HIGH = randfrom(1.04, 1.09);
    // S_STOP_LOW = randfrom(0.94, 0.98);
    // S_FIRST_CHANGE_SIZE = randfrom(0.90, 1.4);
    
    // S_MIN_FIRST_CHANGE = 0.85;
    // S_TOP_HIGH = 1.064;
    // S_STOP_LOW = 0.962;


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
    double first_change = (1 - minute[-1].open / minute[-1].close) * 100;
    double last_change = (1 - minute[0].open / minute[0].close) * 100;
    if (first_change > S_MIN_FIRST_CHANGE) {
        if (last_change > S_MIN_LAST_CHANGE && last_change < first_change * S_FIRST_CHANGE_SIZE) {
            initBet(bet, SELL, minute->close * S_TOP_HIGH,
                    minute->close * S_STOP_LOW);
        }
    }
    // printf("FIRST CHANGE: %-10.3lf LAST CHANGE: %-10.3lf\n", first_change,
    // last_change);


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