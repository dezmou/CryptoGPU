#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    int nbrMinutes;
    Minute *minutes;
} Data;

typedef struct {
    long seed; 
    long res;
} Worker;

__global__ void bake(Data data, Worker *workers) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;
    for (int i =0; i < data.nbrMinutes; i++){
        if (data.minutes[i].open > workers[workerNbr].seed){
            workers[workerNbr].res = 1;
        }
    }
}

Data loadMinutes(char *path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    cudaMallocManaged(&data.minutes, size);
    int rd = read(fd, data.minutes, size);
    if (rd <= 0) {
        printf("ERROR LOAD FILE\n");
        exit(0);
    }
    data.nbrMinutes = size / sizeof(Minute);
    return data;
}

void printMinute(Minute *minute) {
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf VOLUME: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close, minute->volume);
}

int main(){
    Data data = loadMinutes("./data");

    int nbrX = 512;
    int nbrY = 512;
    int nbrThreads = nbrX * nbrY;

    Worker *workers;
    cudaMallocManaged(&workers, nbrThreads * sizeof(Worker));
    for (int i=0; i < nbrThreads; i++){
        workers[i].seed = (double)i;
    }

    bake<<<512, 512>>>(data, workers);
    cudaDeviceSynchronize();
    cudaError_t error = cudaGetLastError();
    if (error != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        exit(-1);
    }

    for (int i=0; i < nbrThreads; i++){
        printf("%ld\n", workers[i].res);
    }

    printMinute(&data.minutes[0]);
    return 0;
}