#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char **argv)
{
    int numElements = 0;
    FILE *fp;
    fp = fopen(argv[1], "rb");

    if(fp != NULL) {
        double sumX = 0.0, sumY = 0.0, sumXmultiplY = 0.0, sumXSquare = 0.0;
        double a = 1.0, b = 1.0;
        int read = fread(&numElements, sizeof(int), 1, fp);
        
        //printf("num elements = %d", numElements);

        double* xValues = (double*)calloc(numElements, sizeof(double));
        double* yValues = (double*)calloc(numElements, sizeof(double));

        read = fread(xValues, sizeof(double), numElements, fp);
        read = fread(yValues, sizeof(double), numElements, fp);

	//printf("x[0] = %4.2f",xValues[0]);

        for(int i = 0; i < numElements; i++) {
            sumXmultiplY += xValues[i] * yValues[i];
            sumY += yValues[i];
            sumX += xValues[i];
            //float sumSq = xValues[i] * xValues[i];
            //printf("xv * xv = %4.2f\n", sumSq);
            sumXSquare = sumXSquare + (xValues[i] * xValues[i]);
            //printf("sumxsquare = %4.2f\n", sumXSquare);
        }
        
        //printf("SUM X = %4.2f", sumX);
        //printf("SUM Y = %4.2f", sumY);
        //printf("SUM X*Y = %4.2f", sumXmultiplY);
        //printf("SUM X^2 = %4.2f", sumXSquare);

        b = (sumXmultiplY - (sumY / sumX) * sumXSquare) / (sumX - (numElements / sumX) * sumXSquare);
        a = (sumY - numElements * b) / sumX;
        fclose(fp);
	//printf("a = %4.2f", a);
	//printf("b = %4.2f", b);
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
