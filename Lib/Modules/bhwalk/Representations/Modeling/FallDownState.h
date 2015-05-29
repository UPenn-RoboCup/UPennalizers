/**
 * @file FallDownState.h
 *
 * Declaration of class FallDownState
 *
 * @author <A href="mailto:timlaue@informatik.uni-bremen.de">Tim Laue</A>
 */

#pragma once

#include "Tools/Streams/Streamable.h"
#include "Tools/Enum.h"

/**
 * @class FallDownState
 *
 * A class that represents the current state of the robot's body
 */
class FallDownState : public Streamable
{
private:
  /**
   * Streaming function
   * @param in Object for streaming in the one direction
   * @param out Object for streaming in the other direction
   */
  void serialize(In* in, Out* out)
  {
    STREAM_REGISTER_BEGIN();
    STREAM(state);
    STREAM(direction);
    STREAM(sidewards);
    STREAM_REGISTER_FINISH();
  }

public:
  /** Current state of the robot's body. */
  ENUM(State,
    undefined,
    upright,
    onGround,
    staggering,
    falling
  );
  State state;

  /** The robot is falling / fell into this direction. */
  ENUM(Direction,
    none,
    front,
    left,
    back,
    right
  );
  Direction direction;

  /** Did the robot fell sidewards before? */
  ENUM(Sidestate,
    noot, // since "not" is already a keyword...
    leftwards,
    rightwards,
    fallen // robot did not get up since last sideward fall
  );
  Sidestate sidewards;

  float odometryRotationOffset;

  /** Default constructor. */
  FallDownState(): state(undefined), direction(none), sidewards(noot), odometryRotationOffset(0) {}

  /** Debug drawing. */
  void draw();
};
