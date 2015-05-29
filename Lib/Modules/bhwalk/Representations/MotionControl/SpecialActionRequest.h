/**
* @file Representations/MotionControl/SpecialActionRequest.h
* This file declares a class to represent special action requests.
* @author <A href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</A>
*/

#pragma once

#include "Tools/Streams/Streamable.h"
#include "Tools/Enum.h"

/**
* @class SpecialActionRequest
* The class represents special action requests.
*/
class SpecialActionRequest : public Streamable
{
private:
  virtual void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(specialAction);
    STREAM(mirror);
    STREAM_REGISTER_FINISH();
  }

public:
  /** ids for all special actions */
  ENUM(SpecialActionID,
    playDead,
    standUpBackNao,
    standUpFrontNao,
    sitDown,
    sitDownKeeper,
    goUp,
    keeperJumpLeftSign
  );

  SpecialActionID specialAction; /**< The special action selected. */
  bool mirror; /**< Mirror left and right. */

  /**
  * Default constructor.
  */
  SpecialActionRequest() : specialAction(playDead), mirror(false) {}

  /**
  * The function searches the id for a special action name.
  * @param name The name of the special action.
  * @return The corresponding id if found, or numOfSpecialActions if not found.
  */
  static SpecialActionID getSpecialActionFromName(const char* name);
};
