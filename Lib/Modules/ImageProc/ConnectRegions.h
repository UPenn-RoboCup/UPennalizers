#ifndef ConnectRegions_h_DEFINED
#define ConnectRegions_h_DEFINED

#include "RegionProps.h"
#include <vector>

typedef unsigned char uint8;

class EquivalenceTable {
 public:
  EquivalenceTable();
  virtual ~EquivalenceTable() {}

  void clear();
  void addEquivalence(int label1, int label2);
  void traverseLinks();
  void removeGaps();
  int getEquivalentLabel(int label) const;
  void ensureAllocated(int label);
  int numLabel();

private:
  std::vector<int> m_table;
  int n_label;
};

int ConnectRegions(std::vector <RegionProps> &props,
		   uint8* image, int n, int m, uint8 mask = 0x01);

int ConnectRegions_obs(std::vector <RegionProps> &props,
		   uint8* image, int n, int m, uint8 mask = 0x01);

#endif
