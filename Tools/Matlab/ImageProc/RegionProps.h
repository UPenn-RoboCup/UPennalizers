#ifndef RegionProps_h_DEFINED
#define RegionProps_h_DEFINED

// Region properties class
class RegionProps {
 public:
  RegionProps();
  virtual ~RegionProps() {}

  void clear();
  void add(int i, int j);

  int area;
  int minI;
  int maxI;
  int minJ;
  int maxJ;

  int sumI;
  int sumJ;
};

// Reverse < for sorting algorithm:
bool operator< (const RegionProps& a, const RegionProps &b);

#endif
