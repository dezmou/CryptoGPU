#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

typedef struct
{
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct
{
    int nbrMinutes;
    Minute *minutes;
} Data;

typedef struct
{
    long seed;
    long res;
} Worker;

__global__ void bake(Data data, Worker *workers)
{
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;
    workers[workerNbr].res = (workerNbr * 5 / 2 + 50 / 3 * 5) % 52 == 0 ? 1 : 0;
    // for (int i = 0; i < data.nbrMinutes * 0.1; i++)
    // {
    //     if (data.minutes[i].open > workers[workerNbr].seed)
    //     {

    //     }
    // }
}

Data loadMinutes(char *path)
{
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    cudaMallocManaged(&data.minutes, size);
    int rd = read(fd, data.minutes, size);
    if (rd <= 0)
    {
        printf("ERROR LOAD FILE\n");
        exit(0);
    }
    data.nbrMinutes = size / sizeof(Minute);
    return data;
}

void printMinute(Minute *minute)
{
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf VOLUME: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close, minute->volume);
}

void searchPike(Data data)
{
    printf("%d\n", data.nbrMinutes);
    int founds = 0;
    for (int i = 40; i < data.nbrMinutes - 40; i++)
    {
        double chien = data.minutes[i].open / data.minutes[i + 20].open;
        if (chien > 1.025 || chien < 0.975)
        {
            printf("%lf %d\n", chien, founds);
            founds += 1;
        }
    }
}

int main()
{
    Data data = loadMinutes("./data");
    // searchPike(data);

    int nbrX = 4096 * 8;
    int nbrY = 1024;
    int nbrThreads = nbrX * nbrY;

    // Worker *ramWorkers;
    // malloc(ramWorkers, nbrThreads * sizeof(Worker));

    Worker *workers;

    cudaMalloc(&workers, nbrThreads * sizeof(Worker));
    // workers = (Worker *)malloc(nbrThreads * sizeof(Worker));


    // cudaMallocManaged(&workers, nbrThreads * sizeof(Worker));
    for (long i = 0; 1; i++)
    {
        bake<<<nbrX, nbrY>>>(data, workers);
        cudaDeviceSynchronize();
        cudaError_t error = cudaGetLastError();
        if (error != cudaSuccess)
        {
            printf("CUDA error: %s\n", cudaGetErrorString(error));
            exit(-1);
        }
        if (i % 10 == 0)
        {
            printf("DONE %ld - %ld B\n", i, i * nbrX * nbrY / 1000000000);
        }
        if (i * nbrX * nbrY / 1000000000 >= 100){
            // break;
        }
    }

    // for (long i = 0; 1; i++)
    // {
    //     long chien = i * 5 / 2 + 50 / 3 * 5;
    //     // workers[i % 2 == 0 ? 0 : 1] = chien;
    //     workers[1].res = chien % 52 == 0 ? 1 : 0;

    //     if (i % 1000000 == 0)
    //     {
    //         printf("DONE %ldM\n", i / 1000000);
    //     }
    // }

    // printMinute(&data.minutes[0]);
    return 0;
}