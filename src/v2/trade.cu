#include "trade.h"

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

void printSeed(Seed *seed) {
    printf("CH:%-12.02lf CH:%-12.02lf\n", seed->chien, seed->lapin);
}

Seed scanSeed(char *seedStr) {
    Seed seed;
    sscanf(seedStr, "CH:%lf LP:%lf\n", &seed.chien, &seed.lapin);
    return seed;
}

Seed plantSeed() {
    Seed seed;
    seed.chien = randfrom(5, 14000);
    return seed;
}

Data loadMinutes(char *path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
#ifdef PLAY
    data.minutes = (Minute*)malloc(size);
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

__host__ __device__ void printMinute(Minute *minute, int cursor) {
    if (cursor != -1) {
        printf("~> %-6d | ", cursor + 2);
    }
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}