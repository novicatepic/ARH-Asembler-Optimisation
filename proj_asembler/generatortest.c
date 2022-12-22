#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <math.h>

#ifndef RAND_MAX
#define RAND_MAX ((int) (unsigned)~0 >> 1)
#endif

//inclusive
float generateRandomFloat(float low, float high) {
    
    float result;
    result = (float)rand() / ((float) RAND_MAX + 1);
    return (low + result * (high - low));
}

int num_elements = 100000;

int main() {
    srand((int)time(NULL));
    float *xValues, *yValues;
    xValues = (float*)calloc(num_elements, sizeof(float));
    yValues = (float*)calloc(num_elements, sizeof(float));

    FILE* fp = fopen("entry_file2", "wb");

    if(fp != NULL) {
        fwrite(&num_elements, sizeof(int), 1, fp);
        for(int i = 0; i < num_elements; i++) {
            //float num1 = roundf(generateRandomFloat(1, 10) * 100) / 100;
            //printf("num1 = %4.2f",num1);
            //float num2 = roundf(generateRandomFloat(1000, 2000) * 100) / 100;
            //printf("num2 = %4.2f",num2);
            xValues[i] = generateRandomFloat(1.0, 10.0);
            yValues[i] = generateRandomFloat(1.0, 10.0);
        }
        fwrite(xValues, sizeof(float), num_elements, fp);
        fwrite(yValues, sizeof(float), num_elements, fp);

        fclose(fp);
    }
    

    //double ran2 = myGenerator();
    //printf("2=%lf", ran2);

    return 0;
}
