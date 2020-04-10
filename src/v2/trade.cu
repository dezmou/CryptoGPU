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