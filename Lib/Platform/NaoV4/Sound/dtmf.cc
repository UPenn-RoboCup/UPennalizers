#include "dtmf.h"
#include "fft.h"

//#define DEBUG_DTMF

// TODO: frame number should not be here, temporary for matlab testing
//long frameNumber = 0;

char signalTone = '\0';

void print_tone_resp(double *qRow, double *qRow2, double *qCol, double *qCol2) {
  printf("qRow:\t");
  for (int i = 0; i < NFREQUENCY; i++) {
    printf("% 4.3f  ", qRow[i]);
  }
  printf("\n");
  printf("qRow2:\t");
  for (int i = 0; i < NFREQUENCY; i++) {
    printf("% 4.3f  ", qRow2[i]);
  }
  printf("\n");

  printf("qCol:\t");
  for (int i = 0; i < NFREQUENCY; i++) {
    printf("% 4.3f  ", qCol[i]);
  }
  printf("\n");
  printf("qCol2:\t");
  for (int i = 0; i < NFREQUENCY; i++) {
    printf("% 4.3f  ", qCol2[i]);
  }
  printf("\n");

}


int gen_tone_pcm(char symbol, short *pcm, int nframe, int leftOnly) {
  // find tone frequencies
  short f1 = 0;
  short f2 = 0;
  for (int r = 0; r < NFREQUENCY; r++) {
    for (int c = 0; c < NFREQUENCY; c++) {
      if (TONE_SYMBOL[r][c] == symbol) {
        f1 = F_ROW[r];
        f2 = F_COL[c];
      }
    }
  }
  if (f1 == 0 || f2 == 0) {
    fprintf(stderr, "gen_tone_pcm: unkown symbol '%c'\n", symbol);
    return -1;
  }

  // generate pcm
  if (leftOnly) {
    for (int i = 0; i < nframe; i++) {
      float t = sin(2.0*M_PI*f1*((double)i/SAMPLING_RATE))
                + sin(2.0*M_PI*f2*((double)i/SAMPLING_RATE));
      t *= (SHRT_MAX/2);

      pcm[2*i] = (short)t;
      pcm[2*i+1] = 0;
    }
  } else {
    for (int i = 0; i < nframe; i++) {
      float t = sin(2.0*M_PI*f1*((double)i/SAMPLING_RATE))
                + sin(2.0*M_PI*f2*((double)i/SAMPLING_RATE));
      t *= (SHRT_MAX/2);

      pcm[2*i] = (short)t;
      pcm[2*i+1] = (short)t;
    }
  }

  return 0;
}


double sort_ratio(double *x, int n, int &index) {
  double xMax = 1, xNext = 1;
  index = 0;

  for (int i = 0; i < n; i++) {
    if (x[i] > xMax) {
      index = i;
      xNext = xMax;
      xMax = x[i];
    } else if (x[i] > xNext) {
      xNext = x[i];
    }
  }

  return (xMax / xNext);
}


void filter_fft(int *x, int *y, int n) {
  static int xFilter[NFFT], yFilter[NFFT];
  static bool init = false;

  if (!init) {
    for (int i = 0; i < PFRAME; i++) {
      // time reverse to filter for correlation
      xFilter[i] = pnSequence[PFRAME-1-i]; 
      yFilter[i] = 0;
    }
    for (int i = PFRAME; i < NFFT; i++) {
      xFilter[i] = 0; 
      yFilter[i] = 0;
    }
    fft(xFilter, yFilter, NFFT);
  }

  for (int i = 0; i < n; i++) {
    // complex multiplication of filter FFT
    int tempr = x[i], tempi = y[i];
    x[i] = tempr*xFilter[i] - tempi*yFilter[i];
    y[i] = tempr*yFilter[i] + tempi*xFilter[i];

    // normalization
    /*
    x[i] /= sqrt(tempr*tempr+tempi*tempi+1.0);
    y[i] /= sqrt(tempr*tempr+tempi*tempi+1.0);
    */

    // not necessary--even playing sound from
    //   own speaker results in correlation < 32768
    // if not normalized, rescale to prevent overflows
    x[i] /= 32768/(2*NFFT);
    y[i] /= 32768/(2*NFFT);
  }

  // take inverse fft to calculate convolution
  fft(x, y, n, -1);
}


double standard_deviation(int *x, int n) {
  double xStd = 0.0;
  for (int i = 0; i < n; i++) {
    xStd += (x[i] * x[i]);
  }
  xStd /= n;
  xStd = sqrt(xStd);

  return xStd;
}


int find_first_max(int *x, int n, double threshold, int offset) {
  int i = 0;

  while (i < (n-offset)) {
    if ((x[i] > threshold) && (x[i+offset] < -threshold)) {
      while ((x[i+1] >= x[i]) && (i < n)) {
        i += 1;
      }

      return i;
    }

    i += 1;
  }

  return -1;
}


int check_tone(short *x, char &toneSymbol, long &frame, int &xLIndex, int &xRIndex, int *leftCorrOut, int *rightCorrOut) {
  static int toneCount = 0;
  static char prevSymbol = '\0';
  static long startFrame = 0;

  static int xL[NFFT], yL[NFFT], xR[NFFT], yR[NFFT];
  static int leftCorr[NCORRELATION], rightCorr[NCORRELATION];

  double qLRow[NFREQUENCY], qLRow2[NFREQUENCY];
  double qLCol[NFREQUENCY], qLCol2[NFREQUENCY];
  double qRRow[NFREQUENCY], qRRow2[NFREQUENCY];
  double qRCol[NFREQUENCY], qRCol2[NFREQUENCY];
  int kLRow, kLCol, kRRow, kRCol;
  double rowLRatio, colLRatio;
  double rowRRatio, colRRatio;

  // extract left/right channels
  for (int i = 0; i < PFRAME; i++) {
    xL[i] = x[2*i]; 
    yL[i] = 0;
    xR[i] = x[2*i+1]; 
    yR[i] = 0;
  }
  for (int i = PFRAME; i < NFFT; i++) {
    xL[i] = 0; 
    yL[i] = 0;
    xR[i] = 0; 
    yR[i] = 0;
  }

  // compute fft of left channel
  fft(xL, yL, NFFT);

  // compute the magnitude of the frequency response for each tone
  for (int i = 0; i < NFREQUENCY; i++) {
    // iRow is the array index corresponding to the row (low) frequency
    int iRow = NFFT_MULTIPLIER * K_ROW[i];
    qLRow[i] = xL[iRow]*xL[iRow] + yL[iRow]*yL[iRow];
    qLRow2[i] = xL[2*iRow]*xL[2*iRow] + yL[2*iRow]*yL[2*iRow];

    // iCow is the array index corresponding to the column (high) frequency
    int iCol = NFFT_MULTIPLIER * K_COL[i];
    qLCol[i] = xL[iCol]*xL[iCol] + yL[iCol]*yL[iCol];
    qLCol2[i] = xL[2*iCol]*xL[2*iCol] + yL[2*iCol]*yL[2*iCol];
  }

  // find ratio of max 2 elements
  //  kLRow and kLCol are indicies of max elements
  rowLRatio = sort_ratio(qLRow, 4, kLRow);
  colLRatio = sort_ratio(qLCol, 4, kLCol);

  // are we are still waiting for the tone signal?
  if (toneCount < THRESHOLD_COUNT) {
    // check the expected tone frequency response is within the threshold
    //  max frequency response is less than 2 times greater than the second highest?
    //  TODO: what is qRow2
    if ((rowLRatio < THRESHOLD_RATIO1)
        || (qLRow[kLRow] < THRESHOLD_RATIO2*qLRow2[kLRow])
        || (colLRatio < THRESHOLD_RATIO1)
        || (qLCol[kLCol] < THRESHOLD_RATIO2*qLCol2[kLCol])) {

      toneCount = 0;
      return 0;
    }

    // check that the tone detected is the signal tone
    //   if the signalTone is set to '\0' accecpt and tones
    // NOTE: this only needs to be checked for one ear since 
    //    both ear tones must be the same
    if (signalTone != '\0') {
      // if the detected tone is not the signal tone
      //  reset the counter
      if (TONE_SYMBOL[kLRow][kLCol] != signalTone) {
        toneCount = 0;
        return 0;
      }
    }
  }

  // compute fft of right channel
  fft(xR, yR, NFFT);

  // compute the magnitude of the frequency response for each tone
  for (int i = 0; i < NFREQUENCY; i++) {
    // iRow is the array index corresponding to the row (low) frequency
    int iRow = NFFT_MULTIPLIER * K_ROW[i];
    qRRow[i] = xR[iRow]*xR[iRow] + yR[iRow]*yR[iRow];
    qRRow2[i] = xR[2*iRow]*xR[2*iRow] + yR[2*iRow]*yR[2*iRow];

    // iCow is the array index corresponding to the column (high) frequency
    int iCol = NFFT_MULTIPLIER * K_COL[i];
    qRCol[i] = xR[iCol]*xR[iCol] + yR[iCol]*yR[iCol];
    qRCol2[i] = xR[2*iCol]*xR[2*iCol] + yR[2*iCol]*yR[2*iCol];
  }

  // find ratio of max 2 elements
  //  kRRow and kRCol are indicies of max elements
  rowRRatio = sort_ratio(qRRow, 4, kRRow);
  colRRatio = sort_ratio(qRCol, 4, kRCol);

  if (toneCount < THRESHOLD_COUNT) {
    if ((rowRRatio < THRESHOLD_RATIO1)
        || (kRRow != kLRow)
        || (qRRow[kRRow] < THRESHOLD_RATIO2*qRRow2[kRRow])
        || (colRRatio < THRESHOLD_RATIO1)
        || (kRCol != kLCol)
        || (qRCol[kRCol] < THRESHOLD_RATIO2*qRCol2[kRCol])) {

      toneCount = 0;
      return toneCount;
    }
  }


  // get tone symbol
  char symbol = TONE_SYMBOL[kLRow][kLCol];

#ifdef DEBUG_DTMF
  printf("symbol: '%c' :: t1 = (%1.3f, %1.3f)  (%1.3f, %1.3f) :: t2 = (%1.3f < %1.3f, %1.3f < %1.3f)  (%1.3f < %1.3f, %1.3f < %1.3f)\n", symbol, rowLRatio, colLRatio, rowRRatio, colRRatio,
          qLRow[kLRow], THRESHOLD_RATIO2*qLRow2[kLRow], qLCol[kLCol], THRESHOLD_RATIO2*qLCol2[kLCol], qRRow[kRRow], THRESHOLD_RATIO2*qRRow2[kRRow], qRCol[kRCol], THRESHOLD_RATIO2*qRCol2[kRCol]);
#endif


  // is this the first tone?
  //  or has the tone changed before expected
  if ((toneCount == 0) 
      || ((toneCount < THRESHOLD_COUNT) && (symbol != prevSymbol))) {
    // reset the tone count
    prevSymbol = symbol;
    toneCount = 1;
    return toneCount;
  } else {
    toneCount++;
  }

  if (toneCount == THRESHOLD_COUNT) {
    // we have heard the tone for the expected amount of time
    //  TODO: what is the significance of the start frame
    //  TODO: is this 4 supposed to be NUM_CHIRP_COUNT
    //startFrame = frameNumber + 4;

  } else if (toneCount > THRESHOLD_COUNT) {
    // compute cross correlation of the left and right channels
    filter_fft(xL, yL, NFFT);
    filter_fft(xR, yR, NFFT);

    int nCorr = toneCount - (THRESHOLD_COUNT+1);
    if (nCorr > 0) {
      for (int i = 0; i < PFRAME-1; i++) {
        leftCorr[(nCorr-1)*PFRAME+i+1] += xL[i];
        rightCorr[(nCorr-1)*PFRAME+i+1] += xR[i];
      }
    }
    for (int i = 0; i < PFRAME; i++) {
      leftCorr[nCorr*PFRAME+i] = xL[PFRAME-1+i];
      rightCorr[nCorr*PFRAME+i] = xR[PFRAME-1+i];
    }

    // have we reached the end of the expected audio signal?
    if (toneCount == THRESHOLD_COUNT + NUM_CHIRP_COUNT) {
      // if the output correlation arrays are given, copy the data to them
      if (leftCorrOut != NULL && rightCorrOut != NULL) {
        for (int i = 0; i < NCORRELATION; i++) {
          leftCorrOut[i] = leftCorr[i];
          rightCorrOut[i] = rightCorr[i];
        }
      }

      // compute standard deviation of the left/right correlation
      double xLStd = standard_deviation(leftCorr, NCORRELATION);
      double xRStd = standard_deviation(rightCorr, NCORRELATION);

      // finished cross correlating the stereo signal
      //  set output parameters

      // find first max zero crossing
      //  TODO: set stdThreshold for correlation matching
      //const double stdThreshold = 2.0;
      const double stdThreshold = 3.0;
      xLIndex = find_first_max(leftCorr, NCORRELATION, stdThreshold*xLStd, PFRAME);
      xRIndex = find_first_max(rightCorr, NCORRELATION, stdThreshold*xRStd, PFRAME);
      toneSymbol = prevSymbol;
      frame = startFrame;

      printf("DTMF: '%c' :: (%d, %d)\n", prevSymbol, xLIndex, xRIndex);

      // reset tone count
      toneCount = 0;

      return -1;
    }
  }

  return toneCount;
}

int cross_correlation(short *x, int *leftCorr, int *rightCorr) {
  static int toneCount = 0;

  static int xL[NFFT], yL[NFFT], xR[NFFT], yR[NFFT];
  //static int leftCorr[NCORRELATION], rightCorr[NCORRELATION];

  // extract left/right channels
  for (int i = 0; i < PFRAME; i++) {
    xL[i] = x[2*i]; 
    yL[i] = 0;
    xR[i] = x[2*i+1]; 
    yR[i] = 0;
  }
  for (int i = PFRAME; i < NFFT; i++) {
    xL[i] = 0; 
    yL[i] = 0;
    xR[i] = 0; 
    yR[i] = 0;
  }

  // compute fft of left channel
  fft(xL, yL, NFFT);

  // compute fft of right channel
  fft(xR, yR, NFFT);

  // compute cross correlation of the left and right channels
  filter_fft(xL, yL, NFFT);
  filter_fft(xR, yR, NFFT);

  for (int i = 0; i < PFRAME; i++) {
    leftCorr[i] = xL[PFRAME-1+i];
    rightCorr[i] = xR[PFRAME-1+i];
  }

  /*
  // compute standard deviation of the left/right correlation
  double xLStd = standard_deviation(leftCorr, NCORRELATION);
  double xRStd = standard_deviation(rightCorr, NCORRELATION);

  // find first max zero crossing
  const double stdThreshold = 3;
  xLIndex = find_first_max(leftCorr, NCORRELATION, stdThreshold*xLStd, PFRAME);
  xRIndex = find_first_max(rightCorr, NCORRELATION, stdThreshold*xRStd, PFRAME);
  toneSymbol = prevSymbol;
  frame = startFrame;
  */

  return 0;
}

