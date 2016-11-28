#ifndef __CSV
#define __CSV

/*
 * http://stackoverflow.com/questions/1120140/csv-parser-in-c
 */
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>

#include <cv.h>

void populateTrainingMatrix(CvMat* trainData, CvMat* trainClasses, const char* filename);

#endif

