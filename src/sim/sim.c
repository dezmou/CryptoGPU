#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#define KNRM "\x1B[0m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

#define NO_BET 0
#define BUY 1
#define SELL 2

// #define TIME_START 200000
#define TIME_START 50
// #define AMOUNT_STOP 200000
#define AMOUNT_STOP 9999999999999
#define FEE_TAKER 0.0004
#define FEE_MAKER 0.0004

#define LEARN 0

#define BET_AMOUNT 10000
// #define FEE 0.0000

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    int type;
    double price;
} Order;

typedef struct {
    int type;
    long startCursor;
    double amount;
    double price;
    double closeWin;
    double closeLose;
    double totalFee;
} Bet;

typedef struct {
    long cursor;
    double bank;
    Bet *bet;
    Minute *minutes;
    int nbrBets;
    double totalFee;
    long nbrWon;
    long nbrLost;
    int flatScore;
    int nbrFlatScore;
    double lastFlatBank;
    double variance;
} Broker;

typedef struct {
    Minute *data;
    int nbrMinutes;
} Env;

Env *e;

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

Broker *newBroker() {
    Broker *broker = malloc(sizeof(Broker));
    broker->cursor = TIME_START;
    broker->bet = NULL;
    broker->minutes = e->data;
    broker->bank = 0;
    broker->nbrBets = 0;
    broker->totalFee = 0;
    broker->nbrWon = 0;
    broker->nbrLost = 0;
    broker->flatScore = 0;
    broker->nbrFlatScore = 0;
    broker->lastFlatBank = 0;
    broker->variance = 0;
    return broker;
}

void printMinute(Minute *minute) {
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}

Bet newBet() {
    Bet bet;
    bet.type = NO_BET;
    bet.totalFee = 0;
    bet.amount = 0.015;
    return bet;
}

typedef struct {
    double change_before_long;
    long change_before_long_steps;
    double closeWin;
    double closeLose;
    int period_for_variance;
    double maxVariance;
} Potards;

Potards *newPotards() {
    Potards *res = malloc(sizeof(Potards));
    res->change_before_long = 1.35;
    res->change_before_long_steps = 10;
    res->closeWin = 0.64;
    res->closeLose = 3.55;
    res->period_for_variance = 40;
    res->maxVariance = 17.11;
    if (LEARN) {
        res->change_before_long = randfrom(0.01, 5);
        res->change_before_long_steps = (long)randfrom(1, 50);
        res->closeWin = randfrom(0.05, 5);
        res->closeLose = randfrom(0.05, 5);
        res->maxVariance = randfrom(1, 20);
    }
    return res;
}

double getVariance(Minute *minute, Potards *potards) {
    double min = 99999999999;
    double max = -9999999999;
    for (int cursor = -(potards->period_for_variance + 1); cursor <= 0; cursor++) {
        if (minute[cursor].low < min) {
            min = minute[cursor].low;
        }
        if (minute[cursor].high > max) {
            max = minute[cursor].high;
        }
    }
    return (max / min * 100) - 100;
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
    
    
    if (change_before_long > potards->change_before_long && variance < potards->maxVariance) {

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

FILE *fp;

void closeBet(Broker *broker, Bet *bet, double price) {
    double usd;
    double closePrice = price;
    if (bet->type == BUY) {
        // printf("CHENAPAN\n");
        usd = bet->amount * closePrice;
    } else if (bet->type = SELL) {
        usd = bet->amount * (bet->price + (bet->price - closePrice));
    }
    double fee = usd * FEE_MAKER;
    broker->bank += usd;
    broker->bank += -fee;
    broker->bet = NULL;
    broker->totalFee += fee;
    broker->nbrBets += 1;
    
    if (!LEARN) {
        printMinute(&broker->minutes[broker->cursor]);
        fprintf(fp, "%lf,%lf,%lf\n", broker->minutes[broker->cursor].close,
                broker->bank, broker->totalFee);
        printf(
            "%-4s STA %-7ld CLO: %-7ld BK: %-9.2lf PRI: %-10.2lf CLW: %-10.2lf "
            "CLL: "
            "%-10.2lf "
            "ACT: %-10.2lf FEE: %-10.5lf TFE: %-10.5lf  NBT: %-6d FL: "
            "%-5d\n\n\n",
            (bet->type == BUY ? "BUY" : "SELL"), bet->startCursor + 2,
            broker->cursor + 2, broker->bank, bet->price, bet->closeWin,
            bet->closeLose, broker->minutes[broker->cursor].close, fee,
            broker->totalFee, broker->nbrBets, broker->flatScore);
    }
    printf(KWHT);
    // getchar();
}

int tickBroker(Broker *broker) {
    do {
        broker->cursor += 1;
        
        
        if (broker->cursor % 50000 == 0) {
            if (broker->bank > broker->lastFlatBank){
                broker->flatScore += 1;
            } else if (broker->bank < broker->lastFlatBank){
                broker->flatScore += -1;
            } 
            // broker->flatScore += (broker->bank > broker->lastFlatBank) ? 1 : 0;
            broker->lastFlatBank = broker->bank;
            broker->nbrFlatScore += 1;
        }
        if (broker->bet) {
            Bet *bet = broker->bet;
            if (bet->type == BUY) {
                if (broker->minutes[broker->cursor].low <= bet->closeLose) {
                    // lose
                    printf(KRED);
                    closeBet(broker, bet, bet->closeLose);
                    broker->nbrLost++;
                } else if (broker->minutes[broker->cursor].high >=
                           bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet, bet->closeWin);
                    broker->nbrWon++;
                }
            } else if (bet->type == SELL) {
                if (broker->minutes[broker->cursor].high >= bet->closeLose) {
                    // lose
                    printf(KRED);
                    closeBet(broker, bet, bet->closeLose);
                    broker->nbrLost++;
                } else if (broker->minutes[broker->cursor].low <=
                           bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet, bet->closeWin);
                    broker->nbrWon++;
                }
            }
        }
        if (broker->cursor >= e->nbrMinutes - 1 ||
            (broker->cursor - TIME_START) > AMOUNT_STOP) {
            return 0;
        }
    } while (broker->bet != NULL);
    return 1;
}

void openBet(Broker *broker, Bet *bet) {
    double usd = bet->amount * broker->minutes[broker->cursor].close;
    double fee = usd * FEE_MAKER;
    bet->price = broker->minutes[broker->cursor].close;
    broker->bank += -usd;
    broker->bank += -fee;
    broker->bet = bet;
    broker->totalFee += fee;
    bet->startCursor = broker->cursor;
    if (!LEARN) {
        printMinute(&broker->minutes[broker->cursor]);
    }
}

void bake(Potards *potards, Broker *broker) {
    // printf("%-10.2lf\n", broker->minute[2].volume);
    do {
        Bet bet = analyse(&broker->minutes[broker->cursor], potards);
        if (bet.type) {
            openBet(broker, &bet);
        }
    } while (tickBroker(broker));
}

void fillData() {
    int fd = open("../../data/bin/BTCUSDT", O_RDONLY);
    // int fd = open("ETHUSDT", O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    e->data = malloc(size);
    read(fd, e->data, size);
    e->nbrMinutes = size / sizeof(Minute);
}

int main() {
    if (!LEARN) {
        fp = fopen("res.csv", "w");
        fprintf(fp, "price, bank, fee\n");
    }
    srand(time(NULL));
    e = malloc(sizeof(e));
    fillData();
    double maxBank = -999999999;
    double maxRoi = -9999999999;
    int maxFlatLine = -9999999;
    for (int i = 0; i < 100000000; i++) {
        Potards *potard = newPotards();
        Broker *broker = newBroker();
        bake(potard, broker);
        double roi = broker->bank / broker->nbrBets;
        if ((broker->bank > maxBank || broker->flatScore > maxFlatLine) && broker->nbrBets > 100 && broker->bank > 0 && broker->flatScore > 4) {
            // if (broker->flatScore > maxFlatLine && broker->bank > 0 &&
            // broker->nbrBets > 1000) {
            printf(
                "BK: %-8.2lf  NB: %-5d CBL: %-8.2lf CBLS: %-8.2ld CLW: %-8.2lf "
                "CLS: %-8.2lf FEE: %-8.2lf ROI: %-8.2lf NBW: %5ld NBL: %5ld "
                "FL: %-5d MXV: %-8.2lf\n",
                broker->bank, broker->nbrBets, potard->change_before_long,
                potard->change_before_long_steps, potard->closeWin,
                potard->closeLose, broker->totalFee, roi, broker->nbrWon,
                broker->nbrLost, broker->flatScore, potard->maxVariance);
            maxBank = broker->bank;
            maxFlatLine = broker->flatScore;
        }
        free(potard);
        free(broker);
        if (!LEARN) {
            break;
            fclose(fp);
        }
    }

    return 0;
}