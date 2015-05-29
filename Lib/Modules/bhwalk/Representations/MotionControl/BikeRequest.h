/**
* @file Representations/MotionControl/BikeRequest.h
* @author <a href="mailto:judy@informatik.uni-bremen.de">Judith M�ller</a>
*/

#pragma once

#include "Tools/Enum.h"
#include "Tools/Streams/Streamable.h"
//#include "Modules/MotionControl/BIKEParameters.h"

class BikeRequest : public Streamable
{
private:

  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(bMotionType);
    STREAM(mirror);
    STREAM(dynamical);
    STREAM(ballSpecial);
//    STREAM(dynPoints);
    STREAM_REGISTER_FINISH();
  }

public:

  ENUM(BMotionID,
    kickForward,
    newKick,
    none
  );

  bool mirror, dynamical, ballSpecial;
  BMotionID bMotionType;
//  std::vector<DynPoint> dynPoints;

  BikeRequest& operator=(const BikeRequest& other)
  {
    mirror = other.mirror;
    dynamical = other.dynamical;
    bMotionType = other.bMotionType;
//    dynPoints = other.dynPoints;
    ballSpecial = other.ballSpecial;
    return *this;
  }

  static BMotionID getBMotionFromName(const char* name);

  BikeRequest(): mirror(false), dynamical(false), ballSpecial(false), bMotionType(none) {};
};
