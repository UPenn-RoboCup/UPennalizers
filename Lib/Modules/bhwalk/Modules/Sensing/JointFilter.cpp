/**
* @file JointFilter.cpp
* Implementation of module JointFilter.
* @author Colin Graf
*/

#include "JointFilter.h"

//MAKE_MODULE(JointFilter, Sensing)
//
//void JointFilter::update(FilteredJointDataPrev& filteredJointDataPrev)
//{
//  (FilteredJointData&) filteredJointDataPrev = theFilteredJointData;
//}

void JointFilter::update(FilteredJointData& filteredJointData, const JointData& theJointData)
{
  for(int i = 0; i < JointData::numOfJoints; ++i)
    if(theJointData.angles[i] != JointData::off)
      filteredJointData.angles[i] = theJointData.angles[i];
    else if(filteredJointData.angles[i] == JointData::off)
      filteredJointData.angles[i] = 0;
  filteredJointData.timeStamp = theJointData.timeStamp;
}
