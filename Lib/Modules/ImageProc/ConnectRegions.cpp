#include "ConnectRegions.h"
#include <vector>
#include <algorithm>
#include <math.h>

EquivalenceTable::EquivalenceTable() {}

void EquivalenceTable::addEquivalence(int label1, int label2) {
  while (label1 != m_table[label1]) {
    label1 = m_table[label1];
  }

  while (label2 != m_table[label2]) {
    label2 = m_table[label2];
  }

  if (label1 < label2) {
    m_table[label2] = label1;
  } else {
    m_table[label1] = label2;
  }
}

void EquivalenceTable::traverseLinks() {
  for (int i = 0; i < m_table.size(); i++) {
    m_table[i] = m_table[m_table[i]];
  }
}

void EquivalenceTable::removeGaps() {
  int next = 0;
  
  for (int i = 0; i < m_table.size(); i++) {
    int b = m_table[i];
    m_table[i] = (i == b) ? next++ : m_table[b];
  }

  n_label = next - 1;
}

int EquivalenceTable::getEquivalentLabel(int label) const {
  // Note: TraverseLinks() must be called before this function
  return m_table[label];
}

void EquivalenceTable::ensureAllocated(int label) {
  int n = m_table.size();
  for (int i = n; i <= label; i++) {
    m_table.push_back(i);
  }
}

void EquivalenceTable::clear() {
  m_table.clear();
}

int EquivalenceTable::numLabel() {
  // Note: RemoveGaps() must be called before this function
  return n_label;
}

int ConnectRegions(std::vector <RegionProps> &props,
                    uint8* image, int m, int n, uint8 mask) {
  const int NMAX = 256;
  static int label_array[NMAX][NMAX];
  static EquivalenceTable equiv_table;

  if ((m > NMAX) || (n > NMAX)) {
    return -1;
  }

  int nlabel = 1;
  equiv_table.clear();
  equiv_table.ensureAllocated(nlabel);

  // Iterate over pixels in image:
  int n_neighbor = 0;
  int label_neighbor[4];

  for (int j = 0; j < n; j++) {
    for (int i = 0; i < m; i++) {
      
      uint8 pixel = *image++;
      if (!(pixel & mask)) {
        label_array[i][j] = 0;
        continue;
      }

      n_neighbor = 0;
      // Check 4-connected neighboring pixels:
      if ((i > 0) && (label_array[i-1][j])) {
        label_neighbor[n_neighbor++] = label_array[i-1][j];
      }
      if ((j > 0) && (label_array[i][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i][j-1];
      }

      // Check 8-connected neighboring pixels:
      if ((i > 0) && (j > 0) && (label_array[i-1][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i-1][j-1];
      }
      if ((i < n-1) && (j > 0) && (label_array[i+1][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i+1][j-1];
      }
      
      int label;
      if (n_neighbor > 0) {
        label = nlabel;

        // Determine minimum neighbor label
        for (int i_neighbor = 0; i_neighbor < n_neighbor; i_neighbor++) {
          if (label_neighbor[i_neighbor] < label) {
            label = label_neighbor[i_neighbor];
          }
        }

        // Update equivalences
        for (int i_neighbor = 0; i_neighbor < n_neighbor; i_neighbor++) {
          if (label != label_neighbor[i_neighbor]) {
            equiv_table.addEquivalence(label, label_neighbor[i_neighbor]);
          }
        }
      } else {
        label = nlabel++;
        equiv_table.ensureAllocated(label);
      }

      // Set label of current pixel
      label_array[i][j] = label;
    }
  }

  // Clean up equivalence table
  equiv_table.traverseLinks();
  equiv_table.removeGaps();
  nlabel = equiv_table.numLabel();

  props.resize(nlabel);
  for (int i = 0; i < nlabel; i++) {
    props[i].clear();
  }

  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      int label = equiv_table.getEquivalentLabel(label_array[i][j]);

      if (label > 0) {
        props[label-1].add(i, j);
      }
    }
  }

  sort(props.begin(), props.end());
  if (props[0].area > 0) {
    nlabel = props.size();
  } else {
    nlabel = 0;
  }

  return nlabel;
}

int ConnectRegions_obs(std::vector <RegionProps> &props,
                    uint8* image, int m, int n, uint8 mask) {
  const int NMAX = 256;
  static int label_array[NMAX][NMAX];
  static EquivalenceTable equiv_table;

  if ((m > NMAX) || (n > NMAX)) {
    return -1;
  }

  int nlabel = 1;
  equiv_table.clear();
  equiv_table.ensureAllocated(nlabel);

  // Iterate over pixels in image:
  int n_neighbor = 0;
  int label_neighbor[4];

  for (int j = 0; j < n; j++) {
    for (int i = 0; i < m; i++) {
      
      uint8 pixel = *image++;
      if (!(pixel & mask)) {
        label_array[i][j] = 0;
        continue;
      }

      n_neighbor = 0;
      // Check 4-connected neighboring pixels:
      if ((i > 0) && (label_array[i-1][j])) {
        label_neighbor[n_neighbor++] = label_array[i-1][j];
      }
      if ((j > 0) && (label_array[i][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i][j-1];
      }

      // Check 8-connected neighboring pixels:
      if ((i > 0) && (j > 0) && (label_array[i-1][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i-1][j-1];
      }
      if ((i < n-1) && (j > 0) && (label_array[i+1][j-1])) {
        label_neighbor[n_neighbor++] = label_array[i+1][j-1];
      }
      
      int label;
      if (n_neighbor > 0) {
        label = nlabel;

        // Determine minimum neighbor label
        for (int i_neighbor = 0; i_neighbor < n_neighbor; i_neighbor++) {
          if (label_neighbor[i_neighbor] < label) {
            label = label_neighbor[i_neighbor];
          }
        }

        // Update equivalences
        for (int i_neighbor = 0; i_neighbor < n_neighbor; i_neighbor++) {
          if (label != label_neighbor[i_neighbor]) {
            equiv_table.addEquivalence(label, label_neighbor[i_neighbor]);
          }
        }
      } else {
        label = nlabel++;
        equiv_table.ensureAllocated(label);
      }

      // Set label of current pixel
      label_array[i][j] = label;
    }
  }

  // Clean up equivalence table
  equiv_table.traverseLinks();
  equiv_table.removeGaps();
  nlabel = equiv_table.numLabel();

  props.resize(nlabel);
  for (int i = 0; i < nlabel; i++) {
    props[i].clear();
  }

  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      int label = equiv_table.getEquivalentLabel(label_array[i][j]);

      if (label > 0) {
        props[label-1].add(i, j);
      }
    }
  }

  sort(props.begin(), props.end());
  if (props[0].area > 0) {
    nlabel = props.size();
  } else {
    nlabel = 0;
  }

  return nlabel;
}
