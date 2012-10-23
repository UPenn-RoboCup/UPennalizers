#ifndef __DTMF_H__
#define __DTMF_H__

#include "sound_params.h"
#include "pnSequence.h"

#include <math.h>
#include <fcntl.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>

// number of tone frequencies (rows and columns)
const short NFREQUENCY = 4;
// frequency corresponding to each row (low fq) of tone symbols
const short K_ROW[]  = {22, 25, 27, 30};
const short F_ROW[]  = {697,  770,  852,  941};  
// frequency corresponding to each column (high fq) of tone symbols
const short K_COL[]  = {39, 43, 47, 52};
const short F_COL[]  = {1209, 1336, 1477, 1633};
// characters representing each tone
const char TONE_SYMBOL[4][4] = {{'1','2','3','A'},
                                {'4','5','6','B'},
                                {'7','8','9','C'},
                                {'*','0','#','D'}};

// TODO: what does the NFFT_MULTIPLIER represent?
const int NFFT_MULTIPLIER = 2;
// number of elements in the result from the normalized fft 
const int NFFT = NFFT_MULTIPLIER * PFRAME;

// TODO: what do these thresholds mean
//const double THRESHOLD_RATIO1 = 2; // original
//const double THRESHOLD_RATIO2 = 2;// original
const double THRESHOLD_RATIO1 = 1.5;
const double THRESHOLD_RATIO2 = 1.5;
// tone threshold
//const int THRESHOLD_COUNT = 3;
const int THRESHOLD_COUNT = 2;
const int NUM_CHIRP_COUNT = 4;
const int NCORRELATION = NUM_CHIRP_COUNT * PFRAME;


/**
 * print out the the magnitude frequency responses for the touch tones
 */
void print_tone_resp(double *qRow, double *qRow2, double *qCol, double *qCol2);


/**
 * generates the pcm array for the given tone
 *
 * symbol - tone symbol
 * *pcm - pointer to pre-allocated pcm array
 * nfarme - number of pcm frames to generate
 */
int gen_tone_pcm(char symbol, short *pcm, int nframe, int leftOnly = 0);


/**
 * find max two elements of an array
 *
 * *x - double array
 *  n - number of elements in array
 * &index - index of the max element is set
 *
 * return the ratio of the max two elements
 */
double sort_ratio(double *x, int n, int &index);


/**
 * ???
 */
void filter_fft(int *x, int *y, int n);


/**
 * compute the standard deviation of the array
 * *x - integer array
 * n - number of elements of x
 *
 * return standard deviation of the array data
 */
double standard_deviation(int *x, int n);


/**
 * ???
 */
int find_first_max(int *x, int n, double threshold, int offset);


/**
 * main update function for incoming audio frames
 *
 * *x - interleaved (lrlrlr) stereo audio signal of size NUM_SAMPLES
 *
 * return:
 *  tone count or -1 when the correlation is complete
 *
 */
int check_tone(short *x, char &toneSymbol, long &frame, int &xLIndex, int &xRIndex, int *leftCorrOut = NULL, int *rightCorrOut = NULL);


/**
 * stand alone cross correlation function for testing
 *
 * *x - interleaved (lrlrlr) stereo audio signal of size NUM_SAMPLES
 * *leftCorr - pre-allocated array to store the left correlation data
 * *rightCorr - pre-allocated array to store the right correlation data
 */
int cross_correlation(short *x, int *leftCorr, int *rightCorr);

#endif

