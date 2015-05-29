/**
 * @class BHWalkProvider
 *
 * A MotionProvider that uses the B-Human walk engine to compute the next body joints
 *
 * @author Octavian Neamtu
 */

#pragma once

#include <vector>

#include "../WalkCommand.h"
#include "../StepCommand.h"
#include "../DestinationCommand.h"
#include "../BodyJointCommand.h"
#include "../MotionProvider.h"

#include "RoboGrams.h"
#include "RobotLocation.pb.h"

//BH
#include "WalkingEngine.h"

namespace man
{
    namespace motion
    {
        class BHWalkProvider : public MotionProvider
        {
        public:
            BHWalkProvider();
            virtual ~BHWalkProvider() {}

            // Provide calibration boolean to the rest of the system.
            bool calibrated() const;

            // Provide hand speeds to the rest of the system
            float leftHandSpeed() const;
            float rightHandSpeed() const;

            void requestStopFirstInstance();
            void calculateNextJointsAndStiffnesses(
                std::vector<float>&            sensorAngles,
                std::vector<float>&            sensorCurrents,
                const messages::InertialState& sensorInertials,
                const messages::FSR&           sensorFSRs
                );

            void hardReset();
            void resetOdometry();

            void setCommand(const WalkCommand::ptr command);
            void setCommand(const DestinationCommand::ptr command);
            //TODO: I'm taking over StepCommand (currently not used) and making
            //it an odometry destination walk
            void setCommand(const StepCommand::ptr command);

            std::vector<BodyJointCommand::ptr> getGaitTransitionCommand() {
                return std::vector<BodyJointCommand::ptr>();
            }

            void getOdometryUpdate(portals::OutPortal<messages::RobotLocation>& out) const;

            static const float INITIAL_BODY_POSE_ANGLES[Kinematics::NUM_JOINTS];
            //returns only body angles
            //TODO: this is in nature due to the fact that we don't separate head providers
            //from body providers - if we did we could separate the methods for each
            std::vector<float> getInitialStance() {
                return std::vector<float>(INITIAL_BODY_POSE_ANGLES,
                                          INITIAL_BODY_POSE_ANGLES + Kinematics::NUM_BODY_JOINTS);
            }

            //TODO: rename this to isGoingToStand since it flags whether we are going to
            //a stand rather than be at a complete standstill
            bool isStanding() const;
            // !isWalkActive() means we're at a complete standstill. everything else is walking.
            bool isWalkActive() const;

            void setStandby(bool value) { standby = value; }

        protected:
            void stand();
            void setActive() {}

//    void playDead();

        private:
            bool requestedToStop;
            bool standby;
            WalkingEngine walkingEngine;
            MotionCommand::ptr currentCommand;
            Pose2D startOdometry;
        };
    } // namespace motion
} // namespace man
