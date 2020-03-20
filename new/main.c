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
double ok = 0;
double ko = 0;

void fillData() {
    int fd = open("BTCUSDT", O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    data = malloc(size);
    read(fd, data, size);
    nbrMinutes = size / sizeof(Minute);
}

void printLine(Minute *minute) {
    // printf("%ld %lf %lf %lf %lf %lf \n", minute->time, minute->open,
    // minute->high, minute->low, minute->close, minute->volume);
    double change = 100000 - (minute->open / minute->close * 100000);
    // printf("%lf %lf %lf\n",minute->open, minute->close, change);
    if (abs(change) > 800) {
        double changeNext = 100000 - (minute->open / minute[100].open * 100000);
        if ((change > 0 && changeNext > 0) || (change < 0 && changeNext < 0)) {
            ok += abs(changeNext);
            printf(KGRN);
        } else {
            ko += abs(changeNext);
            printf(KRED);
        }
        printf(
            "%ld    H-L:%11lf    O-C:%11lf    VO:%11lf      CH:%11lf       "
            "CHN:%11lf     OK:%11lf    KO:%11lf\n",
            minute->time, minute->high - minute->low,
            minute->open - minute->close, minute->volume, change / 1000,
            changeNext / 1000, ok / 1000, ko / 1000);
    }
}

int main() {
    fillData();
    for (cursor = 0; cursor < nbrMinutes; cursor++) {
        printLine(&data[cursor]);
        // break;
    }
    return 0;
}