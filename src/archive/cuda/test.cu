#include <iostream>
#include <math.h>
// Kernel function to add the elements of two arrays
__global__
void add(int n, float *y)
{
  // int index = threadIdx.x;
  // int stride = blockDim.x;
  printf("blockIdx.x: %d  threadIdx.x: %d gridDim.x: %d blockDim.x: %d\n", blockDim.x, threadIdx.x, gridDim.x, blockIdx.x);
}

Minute **loadHistory(int start, int amount) {
    int fd = open("../data/bin/full", O_RDONLY);
    Minute **minutes;
    cudaMallocManaged(&minutes, sizeof(void **) * amount);
    int i = -1;
    while (1) {
        i++;
        cudaMallocManaged(&minutes[i], sizeof(Minute));
        if (read(fd, minutes[i], sizeof(Minute)) < 1 || i == AMOUNT_TEST) break;
    }
    return minutes;
}

int main(void)
{
  int n = 1;
  float *y;
  // Allocate Unified Memory – accessible from CPU or GPU
  cudaMallocManaged(&y, n*sizeof(float));
  y[0] = 5;
  add<<<10, 1>>>(n, y);

  // Wait for GPU to finish before accessing on host
  cudaDeviceSynchronize();

  // Check for errors (all values should be 3.0f)

  // Free memory
  cudaFree(y);
  
  return 0;
}