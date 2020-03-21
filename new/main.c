#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#define KNRM "\x1B[0m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

#define RAKE 0.00075
// #define RAKE 0

#define BUY 1
#define SELL 2

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

Minute *data;
int nbrMinutes;
int cursor;

double bank = 10000;

void fillData() {
    int fd = open("BTCUSDT", O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    data = malloc(size);
    read(fd, data, size);
    nbrMinutes = size / sizeof(Minute);
}

// void printLine(Minute *minute) {
//     // printf("%ld %lf %lf %lf %lf %lf \n", minute->time, minute->open,
//     // minute->high, minute->low, minute->close, minute->volume);
//     double change = 100000 - (minute->open / minute->close * 100000);
//     // printf("%lf %lf %lf\n",minute->open, minute->close, change);
//     if (abs(change) > 800) {
//         nbrBet++;
//         double changeNext = 100000 - (minute->open / minute[5].open *
//         100000); if ((change > 0 && changeNext > 0) || (change < 0 &&
//         changeNext < 0)) {
//             ok += abs(changeNext);
//             // ok -= abs(changeNext * 0.02);
//             printf(KGRN);
//         } else {
//             ko += abs(changeNext);
//             printf(KRED);
//         }
//         printf(
//             "%ld  H-L:%11lf  O-C:%11lf   VO:%11lf   CH:%11lf  "
//             "CHN:%11lf  OK:%11lf   KO:%11lf  DIF:%11lf  BET: %d\n",
//             minute->time, minute->high - minute->low,
//             minute->open - minute->close, minute->volume, change / 1000,
//             changeNext / 1000, ok / 1000, ko / 1000, (ok / ko), nbrBet);
//     }
// }

double bet(Minute *minute, char type, double amount, double closeWin,
           double closeLoss) {
    double fee = amount * RAKE;
    double final = amount;
    for (int i = 0; i < 60; i++) {
        double change = ((minute[i].close / minute->close * 100) - 100) *
                        (type == BUY ? 1 : -1);
        if (change > closeWin || change < -closeLoss) {
            final = amount + (amount * (change * 0.01));
            if (change < 0) {
                printf(KRED);
            } else {
                printf(KGRN);
            }
            printf("%7d |  %lf %lf change %lf final %lf %s bank : %lf\n", i,
                   minute->close, minute[i].close, change, final,
                   type == BUY ? "BUY" : "SELL", bank);
            break;
        }
    }
    fee += final * RAKE;
    final += -fee;
    return final;
}

void play(Minute *minute) {
    double betSize = 100;
    bank += -betSize;
    bank += bet(minute, SELL, betSize, 1.3, 1.3);
    // printf(" bank : %lf\n", bank);
}

int main() {
    fillData();
    for (cursor = 0; cursor < nbrMinutes; cursor += 5000) {
        play(&data[cursor]);
        // getchar();
        // break;
    }
    return 0;
}