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

#define BUY 1
#define SELL 2

#define TIME_START 0
#define FEE 0.0004
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
} Bet;

typedef struct {
    long cursor;
    double bank;
    Bet *bet;
    Minute *minute;
    int nbrBets;
} Broker;

typedef struct {
} Potards;

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

Potards *newPotards() {
    Potards *res = malloc(sizeof(Potards));
    return res;
}

Broker *newBroker() {
    Broker *res = malloc(sizeof(Broker));
    res->cursor = TIME_START;
    res->bet = NULL;
    res->minute = &e->data[res->cursor];
    res->bank = 1000;
    res->nbrBets = 0;
    return res;
}

Bet analyse(Minute *minute) {
    Bet bet;
    bet.type = BUY;
    bet.amount = 0.015;
    bet.closeLose = minute->close * 0.999;
    bet.closeWin = minute->close * 1.001;
    return bet;
}

void closeBet(Broker *broker, Bet *bet) {
    double usd = bet->amount * broker->minute->close;
    double fee = usd * FEE;
    broker->bank += usd;
    broker->bank += -fee;
    broker->bet = NULL;
    printf(
        "STA %-7ld CLO: %-7ld BK: %-9.2lf PRI: %-10.2lf CLW: %-10.2lf CLL: %-10.2lf "
        "ACT: %-10.2lf FEE: %-10.5lf\n", bet->startCursor,
        broker->cursor, broker->bank, bet->price, bet->closeWin, bet->closeLose,
        broker->minute->close, fee);
}

int tickBroker(Broker *broker) {
    do {
        broker->cursor += 1;
        *broker->minute++;

        if (broker->bet) {
            Bet *bet = broker->bet;

            if (bet->type == BUY) {
                if (broker->minute->close >= bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet);
                }
                if (broker->minute->close <= bet->closeLose) {
                    // lose
                    printf(KRED);
                    closeBet(broker, bet);
                }
            } else if (bet->type == SELL) {
                if (broker->minute->close <= bet->closeWin) {
                    // WIN
                    printf(KGRN);
                    closeBet(broker, bet);
                }
                if (broker->minute->close >= bet->closeLose) {
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
    double usd = bet->amount * broker->minute->close;
    double fee = usd * FEE;
    bet->price = broker->minute->close;
    broker->bank += -usd;
    broker->bank += -fee;
    broker->bet = bet;
    bet->startCursor = broker->cursor;
}

void bake(Potards *potards, Broker *broker) {
    do {
        Bet bet = analyse(&e->data[broker->cursor]);
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

    bake(newPotards(), newBroker());

    return 0;
}