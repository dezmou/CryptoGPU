#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIT_SIZE 200
#define NBR_COIN 162
#define BUF 6488
#define MINIMAL_COINS 100

typedef struct {
    double open;
    double high;
    double low;
    double close;
    double volume;
} Data;

typedef struct {
    double time;
    Data data[NBR_COIN];
} Minute;

__global__ void test(Minute **minutes) {
    printf("GLOBAL CALL\n");
    for (int i=0 ;i < 50000 ; i++){
        printf("%lf - %lf\n", minutes[i]->data[3].open, minutes[i]->data[3].volume);
    }
}

int main() {
    // Minute *minute;
    int fd = open("../data/bin/full", O_RDONLY);
    // char *tmpStr = malloc(163);
    // tmpStr[162] = 0;
    // int total = 0;
    Minute **minutes;
    cudaMallocManaged(&minutes, sizeof(void **) * 900000);
    int i = -1;
    while (1) {
        i++;
        cudaMallocManaged(&minutes[i], sizeof(Minute));
        if (read(fd, minutes[i], BUF) < 1) break;
    }
    test<<<1, 1>>>(minutes);
    cudaDeviceSynchronize();
    printf("done\n");
    return 0;
}