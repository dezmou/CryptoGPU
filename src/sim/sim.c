#include "trade.h"


// #define TIME_START 200000
#define TIME_START 50
// #define AMOUNT_STOP 200000
#define AMOUNT_STOP 9999999999999
#define FEE_TAKER 0.0004
#define FEE_MAKER 0.0004

#define LEARN 0

// #define FEE 0.0000

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

Broker newBroker(Data data) {
    // Broker *broker = malloc(sizeof(Broker));
    Broker broker;
    broker.cursor = TIME_START;
    broker.bet = NULL;
    broker.minutes = data.minutes;
    broker.bank = 0;
    broker.nbrBets = 0;
    broker.totalFee = 0;
    broker.nbrWon = 0;
    broker.nbrLost = 0;
    broker.flatScore = 0;
    broker.nbrFlatScore = 0;
    broker.lastFlatBank = 0;
    broker.variance = 0;
    broker.nbrMinutes = data.nbrMinutes;
    return broker;
}

void printMinute(Minute *minute) {
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}

Potards newPotards() {
    Potards res;
    res.change_before_long = 1.35;
    res.change_before_long_steps = 10;
    res.closeWin = 0.64;
    res.closeLose = 3.55;
    res.period_for_variance = 40;
    res.maxVariance = 17.11;
    if (LEARN) {
        res.change_before_long = randfrom(0.01, 5);
        res.change_before_long_steps = (long)randfrom(1, 50);
        res.closeWin = randfrom(0.05, 5);
        res.closeLose = randfrom(0.05, 5);
        res.maxVariance = randfrom(1, 20);
    }
    return res;
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
        if (broker->cursor >= broker->nbrMinutes - 1 ||
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

// "../../data/bin/BTCUSDT"
int main() {
    if (!LEARN) {
        fp = fopen("res.csv", "w");
        fprintf(fp, "price, bank, fee\n");
    }
    srand(time(NULL));
    // e = malloc(sizeof(e));
    Data data = loadMinutes("../../data/bin/BTCUSDT");
    // e->data = data.minutes;
    // e->nbrMinutes = data.nbrMinutes;
    // fillData();
    double maxBank = -999999999;
    double maxRoi = -9999999999;
    int maxFlatLine = -9999999;
    for (int i = 0; i < 100000000; i++) {
        Potards potard = newPotards();
        Broker broker = newBroker(data);
        bake(&potard, &broker);
        double roi = broker.bank / broker.nbrBets;
        if ((broker.bank > maxBank || broker.flatScore > maxFlatLine) && broker.nbrBets > 100 && broker.bank > 0 && broker.flatScore > 4) {
            // if (broker.flatScore > maxFlatLine && broker.bank > 0 &&
            // broker.nbrBets > 1000) {
            printf(
                "BK: %-8.2lf  NB: %-5d CBL: %-8.2lf CBLS: %-8.2ld CLW: %-8.2lf "
                "CLS: %-8.2lf FEE: %-8.2lf ROI: %-8.2lf NBW: %5ld NBL: %5ld "
                "FL: %-5d MXV: %-8.2lf\n",
                broker.bank, broker.nbrBets, potard.change_before_long,
                potard.change_before_long_steps, potard.closeWin,
                potard.closeLose, broker.totalFee, roi, broker.nbrWon,
                broker.nbrLost, broker.flatScore, potard.maxVariance);
            maxBank = broker.bank;
            maxFlatLine = broker.flatScore;
        }
        if (!LEARN) {
            break;
            fclose(fp);
        }
    }

    return 0;
}