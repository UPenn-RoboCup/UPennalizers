/*
  RadonTransform class header
  Written by Daniel D. Lee, 06/2009
  <ddlee@seas.upenn.edu>
*/

#ifndef RadonTransform_h_DEFINED
#define RadonTransform_h_DEFINED

struct LineStats {
  int count;
  double iMean;
  double jMean;
  double iMin;
  double jMin;
  double iMax;
  double jMax;  
};

class RadonTransform {
 public:
  RadonTransform();
  virtual ~RadonTransform() {}

  static const int NR = 128; // Number of radius
  static const int NTH = 90; // Number of angles
  static const int NTRIG = 65536; // Integer trig normalization
  static const int DIAGONAL_THRESHOLD = NTRIG/1.41421356;
  
  void clear();
  void addHorizontalPixel(int i, int j);
  void addVerticalPixel(int i, int j);
  void addPixelToRay(int i, int j, int ith);
 
  struct LineStats &getLineStats();

  int countMax;  
  int count[NTH][NR];
  int thMax;
  int rMax;

  int lineMin[NTH][NR];
  int lineMax[NTH][NR];
  int lineSum[NTH][NR];

  double th[NTH];
  int sinTable[NTH];
  int cosTable[NTH];

  struct LineStats bestLine;
};

#endif
