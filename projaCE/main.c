#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int numElements = 0;
    FILE *fp;
    fp = fopen(argv[1], "rb");

    if(fp != NULL) {
        double sumX = 0.0, sumY = 0.0, sumXmultiplY = 0.0, sumXSquare = 0.0;
        double a = 0.0, b = 0.0;
        int read = fread(&numElements, sizeof(int), 1, fp);

        double* xValues = (double*)calloc(numElements, sizeof(double));
        double* yValues = (double*)calloc(numElements, sizeof(double));

        read = fread(xValues, sizeof(double), numElements, fp);
        read = fread(yValues, sizeof(double), numElements, fp);

        for(int i = 0; i < numElements; i++) {
            sumXmultiplY += xValues[i] * yValues[i];
            sumY += yValues[i];
            sumX += xValues[i];
            sumXSquare += xValues[i] * xValues[i];
        }

        b = (sumXmultiplY - (sumY / sumX) * sumXSquare) / (sumX - (numElements / sumX) * sumXSquare);
        a = (sumY - numElements * b) / sumX;
        fclose(fp);

        fp = fopen(argv[2], "wb");
        if(fp != NULL) {
            fwrite(&a, sizeof(double), 1, fp);
            fwrite(&b, sizeof(double), 1, fp);
            fclose(fp);
        } else {
            printf("Nested error");
        }


    } else {
        printf("Outer error!");
    }


    return 0;
}
