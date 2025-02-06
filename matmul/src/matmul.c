
#include "dataset.h"
#include <stddef.h>

// NxN matrices 
void matmul(int N,  const data_t A[], const data_t B[], data_t C[])
{
  int i, j, k;
 
  for (i = 0; i < N; i++) {
    for (j = 0; j < N; j++) {
      data_t sum = 0;
      for (k = 0; k < N; k++)
        sum += A[j*N + k] * B[k*N + i];
      C[i + j*N] = sum;
    }
  }
}

void matsum(int N, int M, const data_t A[], const data_t B[], data_t C[])
{
  int i, j;

  for (i = 0; i < N; i++) {
    for (j = 0; j < M; j++) {
      C[i*N + j] = A[i*N + j] + B[i*N + j];
    }
  }
}

void main()
{
	static data_t results_data[ARRAY_SIZE];
	matsum(DIM_SIZE, DIM_SIZE, input1_data, input2_data, results_data);
}
