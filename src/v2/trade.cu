#include "trade.h"

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

#define SEEDSTR \
    "%lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf %lf\n"
#define SEEDPARAMS

void printSeed(Seed *seed) {
    printf(SEEDSTR, seed->a, seed->b, seed->c, seed->d, seed->e, seed->f,
           seed->g, seed->h, seed->i, seed->j, seed->k, seed->l, seed->m,
           seed->n, seed->o, seed->p);
}

Seed scanSeed(char *seedStr) {
    Seed seed;
    sscanf(seedStr, SEEDSTR, &seed.a, &seed.b, &seed.c, &seed.d, &seed.e,
           &seed.f, &seed.g, &seed.h, &seed.i, &seed.j, &seed.k, &seed.l,
           &seed.m, &seed.n, &seed.o, &seed.p);
    return seed;
}

DEVICE void printMinute2(Line *line, int cursor) {
    if (cursor != -1) {
        printf("~> %-6d | ", cursor + 2);
    }
    printf(
        "%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf "
        "AVG_C: %-10.5lf\n",
        line->time, line->open, line->high, line->low, line->close,
        line->avgCandle);
}

void createIndicators(Data *data) {
#ifdef PLAY
    data->line = (Line *)malloc(sizeof(Line) * data->nbrMinutes);
#endif
#ifndef PLAY
    cudaMallocManaged(&data->line, sizeof(Line) * data->nbrMinutes);
#endif
    for (int i = 0; i < data->nbrMinutes; i++) {
        double avg = -1;

        if (i > 1405) {
            double totalCandleSize = 0;
            int nbrCandles = 0;
            for (int j = i - 150; j < i - 10; j++) {
                // &data->minutes[j];
                nbrCandles += 1;
                totalCandleSize +=
                    fabs((data->minutes[j].open - data->minutes[j].close));
            }
            avg = totalCandleSize / nbrCandles;
        }
        memcpy(&data->line[i], &data->minutes[i], sizeof(Minute));
        data->line[i].avgCandle = avg;
        printMinute2(&data->line[i], i);
    }
}

Data loadMinutes(char *path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
#ifdef PLAY
    data.minutes = (Minute *)malloc(size);
#endif
#ifndef PLAY
    cudaMallocManaged(&data.minutes, size);
#endif
    int rd = read(fd, data.minutes, size);
    if (rd <= 0) {
        printf("ERROR LOAD FILE\n");
        exit(0);
    }
    data.nbrMinutes = size / sizeof(Minute);
    createIndicators(&data);
    return data;
}

DEVICE void printMinute(Minute *minute, int cursor) {
    if (cursor != -1) {
        printf("~> %-6d | ", cursor + 2);
    }
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}