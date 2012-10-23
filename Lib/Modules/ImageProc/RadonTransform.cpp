/*
  RadonTransform class
  Written by Daniel D. Lee, 06/2009
  <ddlee@seas.upenn.edu>
*/


#include "RadonTransform.h"
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <math.h>
#include <stdint.h>

#ifndef PI
#define PI M_PI
#endif

RadonTransform::RadonTransform() {
  // Initialize trigonometry tables:
  for (int i = 0; i < NTH; i++) {
    //We only need 0 to Pi
    th[i] = PI*i/NTH;
    cosTable[i] = NTRIG*cos(th[i]);
    sinTable[i] = NTRIG*sin(th[i]);
  }

  clear();
}

void RadonTransform::clear() {
  countMax = 0;
  for (int ith = 0; ith < NTH; ith++) {
    for (int ir = 0; ir < NR; ir++) {
      count[ith][ir] = 0;
      lineMin[ith][ir] = INT_MAX;
      lineMax[ith][ir] = INT_MIN;
      lineSum[ith][ir] = 0;
    }
  }
}

void RadonTransform::addPixelToRay(int i, int j, int ith) {
  int ir = abs(cosTable[ith]*i + sinTable[ith]*j)/NTRIG; 
//R value: 0 to MAXR-1
//R index: 0 to NR-1
  int ir1=(ir+1)*NR/MAXR-1;
  count[ith][ir1]++;
  if (count[ith][ir1] > countMax) {
    thMax = ith;
    rMax = ir1;
    countMax = count[ith][ir1];
  }

  // Line statistics:
  int iline = (-sinTable[ith]*i + cosTable[ith]*j)/NTRIG;
  lineSum[ith][ir1] += iline;
  if (iline > lineMax[ith][ir1]) lineMax[ith][ir1] = iline;
  if (iline < lineMin[ith][ir1]) lineMin[ith][ir1] = iline;    
}

void RadonTransform::addHorizontalPixel(int i, int j) {
  for (int ith = 0; ith < NTH; ith++) {
    if (abs(sinTable[ith]) < DIAGONAL_THRESHOLD)
      continue;
    addPixelToRay(i, j, ith);
  }
}

void RadonTransform::addVerticalPixel(int i, int j) {
  for (int ith = 0; ith < NTH; ith++) {
    if (abs(cosTable[ith]) < DIAGONAL_THRESHOLD)
      continue;
    addPixelToRay(i, j, ith);
  }
}

struct LineStats &RadonTransform::getLineStats() {
  bestLine.count = countMax;
  if (countMax == 0) {
    return bestLine;
  }
//R value: 0 to MAXR-1
//R index: 0 to NR-1

  double iR = ((rMax+1)*MAXR/NR-1+.5)*cosTable[thMax];
  double jR = ((rMax+1)*MAXR/NR-1+.5)*sinTable[thMax];
  double lMean = lineSum[thMax][rMax]/countMax;
  double lMin = lineMin[thMax][rMax];
  double lMax = lineMax[thMax][rMax];

  bestLine.iMean = (iR - lMean*sinTable[thMax])/NTRIG;
  bestLine.jMean = (jR + lMean*cosTable[thMax])/NTRIG;
  bestLine.iMin = (iR - lMin*sinTable[thMax])/NTRIG;
  bestLine.jMin = (jR + lMin*cosTable[thMax])/NTRIG;
  bestLine.iMax = (iR - lMax*sinTable[thMax])/NTRIG;
  bestLine.jMax = (jR + lMax*cosTable[thMax])/NTRIG;

  return bestLine;
}

int max(int a, int b){
  if (a>b)
    return a;
  else
    return b;
}
int min(int a, int b){
  if (a<b)
    return a;
  else
    return b;
}

struct LineStats *RadonTransform::getMultiLineStats(
	int ni, int nj, uint8_t *im_ptr){
  static uint8_t colorLine = 0x10;

  int MAXCANDIDATES = 50;
  int thMaxs[MAXCANDIDATES];
  int rMaxs[MAXCANDIDATES];
  int countMaxs[MAXCANDIDATES];

  thMaxs[0]=thMax;
  rMaxs[0]=rMax;
  countMaxs[0]=countMax;

  if (countMax == 0) {
    bestLines[0].count=0;
    return bestLines;
  }


  
  int i_bestLines=1;

/*
  //exhausitive search
  for (int i=1;i<MAXLINES;i++){
    countMaxs[i]=0;
    for (int ith = 0; ith < NTH; ith++) {
      for (int ir = 0; ir < NR; ir++) {
        if ((count[ith][ir]>countMaxs[i])&&
            (count[ith][ir]<countMaxs[i-1])){
	  thMaxs[i]=ith;
	  rMaxs[i]=ir;
	  countMaxs[i]=count[ith][ir];
	}
      }
    }
    if (countMaxs[i]>0)  i_bestLines++;
  }
*/

  int count_threshold = 5;


  for (int ith = 0; ith < NTH; ith++) {
    for (int ir = 0; ir < NR; ir++) {
      if (count[ith][ir]>count_threshold){
	if (i_bestLines<MAXCANDIDATES){
	  thMaxs[i_bestLines]=ith;
	  rMaxs[i_bestLines]=ir;
	  countMaxs[i_bestLines]=count[ith][ir];
	  i_bestLines=i_bestLines+1;
	}
      }
    }
  }
  printf("Line candidates:%d\n",i_bestLines);

  int R_MERGE = 1;
  int TH_MERGE = 5;

  //Merge similar lines

  int mergecount = 0;
  for (int i=0;i<i_bestLines-1;i++){
    for (int j=i+1;j<i_bestLines;j++){
      if ((abs(thMaxs[i]-thMaxs[j])<=TH_MERGE)&&
         (abs(rMaxs[i]-rMaxs[j])<=R_MERGE)&&
         (countMaxs[i]>1) && (countMaxs[j]>1)  ){
	//weighted sum of two lines 
//   	  thMaxs[i]=(thMaxs[i]*countMaxs[i]+thMaxs[j]*countMaxs[j])/
//		  (countMaxs[i]+countMaxs[j]);
//     	  rMaxs[i]=(rMaxs[i]*countMaxs[i]+rMaxs[j]*countMaxs[j])/
//		  (countMaxs[i]+countMaxs[j]);
        mergecount++;
	//Update stats
        if (countMaxs[i]>countMaxs[j]){
/*
           lineMax[thMaxs[i]][rMaxs[i]] = 
               min (lineMin[thMaxs[i]][rMaxs[i]] ,
                  lineMin[thMaxs[j]][rMaxs[j]] );
           lineMin[thMaxs[i]][rMaxs[i]] = 
               max (lineMin[thMaxs[i]][rMaxs[i]] ,
                  lineMin[thMaxs[j]][rMaxs[j]] );
*/
           lineSum[thMaxs[i]][rMaxs[i]] = 
                (lineSum[thMaxs[i]][rMaxs[i]]*countMaxs[i]+
                lineMin[thMaxs[j]][rMaxs[j]]*countMaxs[j])/
		(countMaxs[i]+countMaxs[j]);
 	   countMaxs[i]=countMaxs[i]+countMaxs[j]-1;
           countMaxs[j]=1;
        }else{
/*
           lineMax[thMaxs[j]][rMaxs[j]] = 
               min (lineMin[thMaxs[i]][rMaxs[i]] ,
                  lineMin[thMaxs[j]][rMaxs[j]] );
           lineMin[thMaxs[j]][rMaxs[j]] = 
               max (lineMin[thMaxs[i]][rMaxs[i]] ,
                  lineMin[thMaxs[j]][rMaxs[j]] );
*/
           lineSum[thMaxs[i]][rMaxs[i]] = 
                (lineSum[thMaxs[i]][rMaxs[i]]*countMaxs[i]+
                lineMin[thMaxs[j]][rMaxs[j]]*countMaxs[j])/
		(countMaxs[i]+countMaxs[j]);
 	   countMaxs[j]=countMaxs[i]+countMaxs[j]-1;
           countMaxs[i]=1;
        }
      }
    }
  }

  printf("Line %d merged\n",mergecount);

// Check the fill rate of each lines

  for (int i=0;i<i_bestLines;i++){
    if (countMaxs[i]>5){
      double iR = ((rMaxs[i]+1)*MAXR/NR-1+.5)*cosTable[thMaxs[i]];
      double jR = ((rMaxs[i]+1)*MAXR/NR-1+.5)*sinTable[thMaxs[i]];
      double lMean = lineSum[thMaxs[i]][rMaxs[i]]/countMaxs[i];
      double lMin = lineMin[thMaxs[i]][rMaxs[i]];
      double lMax = lineMax[thMaxs[i]][rMaxs[i]];
      int iMean = (iR - lMean*sinTable[thMaxs[i]])/NTRIG;
      int jMean = (jR + lMean*cosTable[thMaxs[i]])/NTRIG;
      int iMin = (iR - lMin*sinTable[thMaxs[i]])/NTRIG;
      int iMax = (iR - lMax*sinTable[thMaxs[i]])/NTRIG;
      int jMin = (jR + lMin*cosTable[thMaxs[i]])/NTRIG;
      int jMax = (jR + lMax*cosTable[thMaxs[i]])/NTRIG;
      int dLine2 = (iMax-iMin)*(iMax-iMin) + (jMax-jMin)*(jMax-jMin) ;
      int dLine = sqrt(dLine2);
      int fillCount = 0;
      for (int k=0;k < dLine;k++){
	int i_in = iMin + k* sinTable[thMaxs[i]]/NTRIG;
	int j_in = jMin + k* cosTable[thMaxs[i]]/NTRIG;
        uint8_t *im_col = im_ptr + ni*j_in + i_in;
	if (*im_col & colorLine) fillCount=fillCount+1;	
      }
      printf("Count %d, Ang%d, R %d, Fill %d, Len %d\n",
	countMaxs[i], thMaxs[i], rMaxs[i],100*fillCount/dLine,dLine);
      if (fillCount*5<dLine)
	countMaxs[i]=1; //Kill line if fill rate is below 35%
    }
  }

  for (int i=0;i<i_bestLines-1;i++){
    for (int j=i+1;j<i_bestLines;j++){
      if (countMaxs[i]<countMaxs[j]){
	   int temp1,temp2,temp3;
	   temp1=countMaxs[i];
	   temp2=thMaxs[i];
	   temp3=rMaxs[i];

	   countMaxs[i]=countMaxs[j];
	   thMaxs[i]=thMaxs[j];
	   rMaxs[i]=rMaxs[j];

	   countMaxs[j]=temp1;
	   thMaxs[j]=temp2;
	   rMaxs[j]=temp3;
      }
    }
  }


  //Get rid of blank lines
//  while (countMaxs[i_bestLines-1]==0) i_bestLines--;
  //Return top lines 
  if (i_bestLines>=MAXLINES) i_bestLines=MAXLINES-1;
  for (int i=0;i<i_bestLines;i++){
    double iR = ((rMaxs[i]+1)*MAXR/NR-1+.5)*cosTable[thMaxs[i]];
    double jR = ((rMaxs[i]+1)*MAXR/NR-1+.5)*sinTable[thMaxs[i]];
    double lMean = lineSum[thMaxs[i]][rMaxs[i]]/countMaxs[i];
    double lMin = lineMin[thMaxs[i]][rMaxs[i]];
    double lMax = lineMax[thMaxs[i]][rMaxs[i]];
    bestLines[i].count = countMaxs[i];
    bestLines[i].iMean = (iR - lMean*sinTable[thMaxs[i]])/NTRIG;
    bestLines[i].jMean = (jR + lMean*cosTable[thMaxs[i]])/NTRIG;
    bestLines[i].iMin = (iR - lMin*sinTable[thMaxs[i]])/NTRIG;
    bestLines[i].iMax = (iR - lMax*sinTable[thMaxs[i]])/NTRIG;
    bestLines[i].jMin = (jR + lMin*cosTable[thMaxs[i]])/NTRIG;
    bestLines[i].jMax = (jR + lMax*cosTable[thMaxs[i]])/NTRIG;
  }
  printf("Count:");
  for (int i=0;i<i_bestLines;i++){
   printf("%d ",countMaxs[i]);
  }
  printf("\nAngle:");
  for (int i=0;i<i_bestLines;i++){
   printf("%d ",thMaxs[i]);
  }
  printf("\nRadius:");
  for (int i=0;i<i_bestLines;i++){
   printf("%d ",rMaxs[i]);
  }
  printf("\n:");
  return bestLines;
}
