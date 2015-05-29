#include "XOSKinematics.h"
#include "Transform.h"
#include <stdio.h>

/*
void print_transform(Transform tr) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      printf("%.4f ",tr(i,j));
    }
    printf("\n");
  }
  printf("\n");
}
*/

int main()
{
  double pLLeg[6], pRLeg[6], pTorso[6];
  std::vector<double> q;

  for (int i = 0; i < 6; i++) {
    pLLeg[i] = 0;
    pRLeg[i] = 0;
    pTorso[i] = 0;
  }

  pLLeg[1] = +.05;
  pRLeg[1] = -.05;
  pTorso[0] = 0.02;
  //  pTorso[2] = 0.30;
  pTorso[2] = 0.20;
  pTorso[3] = -.12;
  pTorso[4] = .13;
  pTorso[5] = .09;

  Transform trTorso = transform6D(pTorso);
  std::vector<double> pTest = position6D(trTorso);
  printf("pTorso: ");
  for (int i = 0; i < 6; i++) printf("%.4f ", pTorso[i]);
  printf("\n");

  //  nao_kinematics_inverse_legs(q, pLLeg, pRLeg, pTorso, 1);
  q = darwinlc_kinematics_inverse_legs(pLLeg, pRLeg, pTorso, 1);

  for (int i = 0; i < 12; i++) {
    printf("%.4f ", q[i]);
  }
  printf("\n");

  /*
  Transform t = nao_kinematics_forward_lleg(q);
  print_transform(inv(t));

  t = nao_kinematics_forward_rleg(q+6);
  print_transform(inv(t));
  */
}
