#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifndef RAND_MAX
#define RAND_MAX ((int) (unsigned)~0 >> 1)
#endif

//inclusive
double generateRandomDouble(double low, double high) {
    
    double result;
    result = (double)rand() / ((double) RAND_MAX + 1);
    return (low + result * (high - low));
}

int num_elements = 10000;

int main() {
    srand((int)time(NULL));
    double xValues[num_elements];
    double yValues[num_elements];

    FILE* fp = fopen("entry_file2", "wb");

    if(fp != NULL) {
        fwrite(&num_elements, sizeof(int), 1, fp);
        for(int i = 0; i < num_elements; i++) {
            xValues[i] = generateRandomDouble(1, 4);
            yValues[i] = generateRandomDouble(1, 4);
        }
        fwrite(xValues, sizeof(double), num_elements, fp);
        fwrite(yValues, sizeof(double), num_elements, fp);

        fclose(fp);
    }
    

    //double ran2 = myGenerator();
    //printf("2=%lf", ran2);

    return 0;
}