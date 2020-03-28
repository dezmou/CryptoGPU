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

#define TIME_START 10
#define FEE 0.0004

#define LEARN 0
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
    return broker;
}

void printMinute(Minute *minute) {
    printf("%ld %lf\n", minute->time, minute->volume);
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
} Potards;

Potards *newPotards() {
    Potards *res = malloc(sizeof(Potards));
    res->change_before_long = 0.42;
    res->change_before_long_steps = 1;
    res->closeWin = 0.19;
    res->closeLose = 0.15;
    if (LEARN) {
        res->change_before_long = randfrom(0.01, 5);
        res->change_before_long_steps = (long)randfrom(1, 10);
        res->closeWin = randfrom(0.05, 3);
        res->closeLose = randfrom(0.05, 3);
    }
    return res;
}

Bet analyse(Minute *minute, Potards *potards) {
    Bet bet = newBet();

    double change_before_long =
        100 - (minute[-(potards->change_before_long_steps)].close /
               minute->close * 100);
    // printf("%lf %lf %lf\n",minute[-2].close,minute->close
    // ,change_before_long); getchar();
    if (change_before_long > potards->change_before_long) {
        bet.amount = 100 / minute->close;

        bet.type = SELL;
        bet.closeLose = minute->close * (1 + potards->closeLose * 0.01);
        bet.closeWin = minute->close * (1 - potards->closeLose * 0.01);

        // bet.type = BUY;
        // bet.closeLose = minute->close * (1 - 0.01);
        // bet.closeWin = minute->close * (1 + 0.01);
    }
    return bet;
}

void closeBet(Broker *broker, Bet *bet) {
    double usd;
    double closePrice = broker->minutes[broker->cursor].close;
    if (bet->type == BUY) {
        // printf("CHENAPAN\n");
        usd = bet->amount * closePrice;
    } else if (bet->type = SELL) {
        usd = bet->amount * (bet->price + (bet->price - closePrice));
    }
    double fee = usd * FEE;
    broker->bank += usd;
    broker->bank += -fee;
    broker->bet = NULL;
    broker->totalFee += fee;
    broker->nbrBets += 1;
    if (!LEARN) {
        printf(
            "%-4s STA %-7ld CLO: %-7ld BK: %-9.2lf PRI: %-10.2lf CLW: %-10.2lf "
            "CLL: "
            "%-10.2lf "
            "ACT: %-10.2lf FEE: %-10.5lf TFE: %-10.5lf  NBT: %-6d\n",
            (bet->type == BUY ? "BUY" : "SELL"), bet->startCursor + 2,
            broker->cursor + 2, broker->bank, bet->price, bet->closeWin,
            bet->closeLose, broker->minutes[broker->cursor].close, fee,
            broker->totalFee, broker->nbrBets);
    }
    // getchar();
}

int tickBroker(Broker *broker) {
    do {
        broker->cursor += 1;
        if (broker->bet) {
            Bet *bet = broker->bet;
            if (bet->type == BUY) {
                if (broker->minutes[broker->cursor].close >= bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet);
                }
                if (broker->minutes[broker->cursor].close <= bet->closeLose) {
                    // lose
                    printf(KRED);
                    closeBet(broker, bet);
                }
            } else if (bet->type == SELL) {
                if (broker->minutes[broker->cursor].close <= bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet);
                }
                if (broker->minutes[broker->cursor].close >= bet->closeLose) {
                    // lose
                    printf(KRED);
                    closeBet(broker, bet);
                }
            }
        }
        if (broker->cursor >= e->nbrMinutes - 1) {
            return 0;
        }
    } while (broker->bet != NULL);
    return 1;
}

void openBet(Broker *broker, Bet *bet) {
    double usd = bet->amount * broker->minutes[broker->cursor].close;
    double fee = usd * FEE;
    bet->price = broker->minutes[broker->cursor].close;
    broker->bank += -usd;
    broker->bank += -fee;
    broker->bet = bet;
    broker->totalFee += fee;
    bet->startCursor = broker->cursor;
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
    int fd = open("BTCUSDT", O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    e->data = malloc(size);
    read(fd, e->data, size);
    e->nbrMinutes = size / sizeof(Minute);
}

int main() {
    srand(time(NULL));
    e = malloc(sizeof(e));
    fillData();
    double maxBank = -99999;
    double maxRoi = -99999;
    for (int i = 0; i < 100000000; i++) {
        Potards *potard = newPotards();
        Broker *broker = newBroker();
        bake(potard, broker);
        double roi = broker->bank / broker->nbrBets;
        if (broker->bank > maxBank) {
            printf(
                "BK: %-8.2lf  NB: %-5d CBL: %-8.2lf CBLS: %-8.2ld CLW: %-8.2lf "
                "CLS: %-8.2lf FEE: %-8.2lf ROI: %-8.2lf\n",
                broker->bank, broker->nbrBets, potard->change_before_long,
                potard->change_before_long_steps, potard->closeWin,
                potard->closeLose, broker->totalFee, roi);
            maxBank = broker->bank;
        }
        free(potard);
        free(broker);
        if (!LEARN){
            break;
        }
    }

    return 0;
}