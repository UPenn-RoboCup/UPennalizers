#include "BHWalkProvider.h"
#include "Profiler.h"

#include <cassert>
#include <string>
#include <iostream>

#include "bhuman.h"

namespace man
{
namespace motion
{

using namespace boost;

const float BHWalkProvider::INITIAL_BODY_POSE_ANGLES[] =
{
        1.57f, 0.18f, -1.56f, -0.18f,
        0.0f, 0.0f, -0.39f, 0.76f, -0.37f, 0.0f,
        0.0f, 0.0f, -0.39f, 0.76f, -0.37f, 0.0f,
        1.57f, -0.18f, 1.43f, 0.23f
};

/**
 * Since the NBites use a different order for the joints, we use this
 * array to convert between Kinematics::JointName and BHuman's JointData::Joint
 *
 * So the JointData::Joint values in this array are arranged in the order
 * the NBites need them
 */
static const JointData::Joint nb_joint_order[] = {
        JointData::HeadYaw,
        JointData::HeadPitch,
        JointData::LShoulderPitch,
        JointData::LShoulderRoll,
        JointData::LElbowYaw,
        JointData::LElbowRoll,
        JointData::LHipYawPitch,
        JointData::LHipRoll,
        JointData::LHipPitch,
        JointData::LKneePitch,
        JointData::LAnklePitch,
        JointData::LAnkleRoll,
        JointData::RHipYawPitch,
        JointData::RHipRoll,
        JointData::RHipPitch,
        JointData::RKneePitch,
        JointData::RAnklePitch,
        JointData::RAnkleRoll,
        JointData::RShoulderPitch,
        JointData::RShoulderRoll,
        JointData::RElbowYaw,
        JointData::RElbowRoll
};

BHWalkProvider::BHWalkProvider()
    : MotionProvider(WALK_PROVIDER), requestedToStop(false)
{
    hardReset();
}

void BHWalkProvider::requestStopFirstInstance()
{
    requestedToStop = true;
}

bool hasLargerMagnitude(float x, float y) {
    if (y > 0.0f)
        return x > y;
    if (y < 0.0f)
        return x < y;
    return true; // considers values of 0.0f as always smaller in magnitude than anything
}

// return true if p1 has "passed" p2 (has components values that either have a magnitude
// larger than the corresponding magnitude p2 within the same sign)
bool hasPassed(const Pose2D& p1, const Pose2D& p2) {

    return (hasLargerMagnitude(p1.rotation, p2.rotation) &&
            hasLargerMagnitude(p1.translation.x, p2.translation.x) &&
            hasLargerMagnitude(p1.translation.y, p2.translation.y));
}

/**
 * This method converts the NBites sensor and joint input to
 * input suitable for the (BH) B-Human walk, and similarly the output
 * and then interprets the walk engine output
 *
 * Main differences:
 * * The BH joint data is in a different order;
 */
void BHWalkProvider::calculateNextJointsAndStiffnesses(
    std::vector<float>&            sensorAngles,
    std::vector<float>&            sensorCurrents,
    const messages::InertialState& sensorInertials,
    const messages::FSR&           sensorFSRs
    ) 
{

    PROF_ENTER(P_WALK);

    // If our calibration became bad (as decided by the walkingEngine,
    // reset. We will wait until we're recalibrated to walk.
    if (walkingEngine.shouldReset && calibrated())
    {
        std::cout << "We are stuck! Recalibrating." << std::endl;
        hardReset();
    }

    assert(JointData::numOfJoints == Kinematics::NUM_JOINTS);

    if (standby) {
        MotionRequest motionRequest;
        motionRequest.motion = MotionRequest::specialAction;

        //TODO: maybe check what kind of special move we're switching to and change this
        //accordingly
        motionRequest.specialActionRequest.specialAction = SpecialActionRequest::keeperJumpLeftSign;
        walkingEngine.theMotionRequest = motionRequest;

        //anything that's not in the walk is marked as unstable
        walkingEngine.theMotionInfo = MotionInfo();
        walkingEngine.theMotionInfo.isMotionStable = false;

    } else {
    // Figure out the motion request
    // VERY UGLY! re-factor this please TODO TODO TODO
    if (requestedToStop || !isActive()) {
        MotionRequest motionRequest;
        motionRequest.motion = MotionRequest::specialAction;

        //TODO: maybe check what kind of special move we're switching to and change this
        //accordingly
        motionRequest.specialActionRequest.specialAction = SpecialActionRequest::keeperJumpLeftSign;
        walkingEngine.theMotionRequest = motionRequest;

        currentCommand = MotionCommand::ptr();

    } else {
        // If we're not calibrated, wait until we are calibrated to walk
        if (!calibrated())
        {
            MotionRequest motionRequest;
            motionRequest.motion = MotionRequest::stand;

            walkingEngine.theMotionRequest = motionRequest;
        } else if (currentCommand.get() && currentCommand->getType() == MotionConstants::STEP) {

            StepCommand::ptr command = boost::shared_static_cast<StepCommand>(currentCommand);

            Pose2D deltaOdometry = walkingEngine.theOdometryData - startOdometry;
            Pose2D absoluteTarget(command->theta_rads, command->x_mms, command->y_mms);

            Pose2D relativeTarget = absoluteTarget - (deltaOdometry + walkingEngine.upcomingOdometryOffset);

            if (!hasPassed(deltaOdometry + walkingEngine.upcomingOdometryOffset, absoluteTarget)) {

                MotionRequest motionRequest;
                motionRequest.motion = MotionRequest::walk;

                motionRequest.walkRequest.mode = WalkRequest::targetMode;

                motionRequest.walkRequest.speed.rotation = command->gain;
                motionRequest.walkRequest.speed.translation.x = command->gain;
                motionRequest.walkRequest.speed.translation.y = command->gain;

                motionRequest.walkRequest.pedantic = true;
                motionRequest.walkRequest.target = relativeTarget;

                walkingEngine.theMotionRequest = motionRequest;

            } else {
                currentCommand = MotionCommand::ptr();
            }

        } else {
        if (currentCommand.get() && currentCommand->getType() == MotionConstants::WALK) {

            WalkCommand::ptr command = boost::shared_static_cast<WalkCommand>(currentCommand);

            MotionRequest motionRequest;
            motionRequest.motion = MotionRequest::walk;

            motionRequest.walkRequest.mode = WalkRequest::percentageSpeedMode;

            motionRequest.walkRequest.speed.rotation = command->theta_percent;
            motionRequest.walkRequest.speed.translation.x = command->x_percent;
            motionRequest.walkRequest.speed.translation.y = command->y_percent;

            walkingEngine.theMotionRequest = motionRequest;
        } else {
        if (currentCommand.get() && currentCommand->getType() == MotionConstants::DESTINATION) {

            DestinationCommand::ptr command = boost::shared_static_cast<DestinationCommand>(currentCommand);

            MotionRequest motionRequest;
            motionRequest.motion = MotionRequest::walk;

            motionRequest.walkRequest.mode = WalkRequest::targetMode;

            motionRequest.walkRequest.speed.rotation = command->gain;
            motionRequest.walkRequest.speed.translation.x = command->gain;
            motionRequest.walkRequest.speed.translation.y = command->gain;

            motionRequest.walkRequest.target.rotation = command->theta_rads;
            motionRequest.walkRequest.target.translation.x = command->x_mm;
            motionRequest.walkRequest.target.translation.y = command->y_mm;

            motionRequest.walkRequest.pedantic = command->pedantic;

            // Let's do some motion kicking!
            if (command->motionKick) {
                if (command->kickType == 0) {
                    motionRequest.walkRequest.kickType = WalkRequest::sidewardsLeft;
                }
                else if (command->kickType == 1) {
                    motionRequest.walkRequest.kickType = WalkRequest::sidewardsRight;
                }
                else if (command->kickType == 2) {
                    motionRequest.walkRequest.kickType = WalkRequest::left;
                }
                else {
                    motionRequest.walkRequest.kickType = WalkRequest::right;
                }
                motionRequest.walkRequest.kickBallPosition.x = command->kickBallRelX;
                motionRequest.walkRequest.kickBallPosition.y = command->kickBallRelY;
            }

            walkingEngine.theMotionRequest = motionRequest;
        }
        //TODO: make special command for stand
        if (!currentCommand.get()) {
            MotionRequest motionRequest;
            motionRequest.motion = MotionRequest::stand;

            walkingEngine.theMotionRequest = motionRequest;
        }
        }
        }
    }
    }

    //We do not copy temperatures because they are unused
    JointData& bh_joint_data = walkingEngine.theJointData;

    for (int i = 0; i < JointData::numOfJoints; i++)
    {
        bh_joint_data.angles[nb_joint_order[i]] = sensorAngles[i];
    }

    SensorData& bh_sensors = walkingEngine.theSensorData;

    for (int i = 0; i < JointData::numOfJoints; i++)
    {
        bh_sensors.currents[nb_joint_order[i]] = sensorCurrents[i];
    }

    bh_sensors.data[SensorData::gyroX] = sensorInertials.gyr_x();
    bh_sensors.data[SensorData::gyroY] = sensorInertials.gyr_y();

    bh_sensors.data[SensorData::accX] = sensorInertials.acc_x();
    bh_sensors.data[SensorData::accY] = sensorInertials.acc_y();
    bh_sensors.data[SensorData::accZ] = sensorInertials.acc_z();

    bh_sensors.data[SensorData::angleX] = sensorInertials.angle_x();
    bh_sensors.data[SensorData::angleY] = sensorInertials.angle_y();

    bh_sensors.data[SensorData::fsrLFL] = sensorFSRs.lfl();
    bh_sensors.data[SensorData::fsrLFR] = sensorFSRs.lfr();
    bh_sensors.data[SensorData::fsrLBL] = sensorFSRs.lrl();
    bh_sensors.data[SensorData::fsrLBR] = sensorFSRs.lrr();

    bh_sensors.data[SensorData::fsrRFL] = sensorFSRs.rfl();
    bh_sensors.data[SensorData::fsrLFR] = sensorFSRs.lfr();
    bh_sensors.data[SensorData::fsrLBL] = sensorFSRs.lrl();
    bh_sensors.data[SensorData::fsrLBR] = sensorFSRs.lrr();

    walkingEngine.update();

    //ignore the first chain since it's the head one
    for (unsigned i = 1; i < Kinematics::NUM_CHAINS; i++) {
        std::vector<float> chain_angles;
        std::vector<float> chain_hardness;
        for (unsigned j = Kinematics::chain_first_joint[i];
                     j <= Kinematics::chain_last_joint[i]; j++) {
            //position angle
            chain_angles.push_back(walkingEngine.joint_angles[nb_joint_order[j]]);
            //hardness
            if (walkingEngine.joint_hardnesses[nb_joint_order[j]] == 0) {
                chain_hardness.push_back(MotionConstants::NO_STIFFNESS);
            } else {
                chain_hardness.push_back(walkingEngine.joint_hardnesses[nb_joint_order[j]]);
            }

        }
        this->setNextChainJoints((Kinematics::ChainID) i, chain_angles);
        this->setNextChainStiffnesses((Kinematics::ChainID) i, chain_hardness);
    }

    //we only really leave when we do a sweet move, so request a special action
    if (walkingEngine.theMotionSelection.targetMotion == MotionRequest::specialAction
            && requestedToStop) {

        inactive();
        requestedToStop = false;
        //reset odometry - this allows the walk to not "freak out" when we come back
        //from other providers
        walkingEngine.theOdometryData = OdometryData();
    }

    PROF_EXIT(P_WALK);
}

bool BHWalkProvider::isStanding() const {
    return walkingEngine.theMotionRequest.motion == MotionRequest::stand;
}

bool BHWalkProvider::isWalkActive() const {
    return !(isStanding() && walkingEngine.walkingEngineOutput.isLeavingPossible) && isActive();
}

void BHWalkProvider::stand() {
//    bhwalk_out << "BHWalk stand requested" << endl;

    currentCommand = MotionCommand::ptr();
    active();
}

void BHWalkProvider::getOdometryUpdate(portals::OutPortal<messages::RobotLocation>& out) const
{
    portals::Message<messages::RobotLocation> odometryData(0);
    odometryData.get()->set_x(walkingEngine.theOdometryData.translation.x
                              * MM_TO_CM);
    odometryData.get()->set_y(walkingEngine.theOdometryData.translation.y
                              * MM_TO_CM);
    odometryData.get()->set_h(walkingEngine.theOdometryData.rotation);

    out.setMessage(odometryData);
}

void BHWalkProvider::hardReset() {

    inactive();
    //reset odometry
    walkingEngine.theOdometryData = OdometryData();

    MotionRequest motionRequest;
    motionRequest.motion = MotionRequest::specialAction;

    motionRequest.specialActionRequest.specialAction = SpecialActionRequest::standUpBackNao;
    currentCommand = MotionCommand::ptr();

    walkingEngine.inertiaSensorCalibrator.reset();

    requestedToStop = false;
}

//void BHWalkProvider::playDead() {
//    MotionRequest motionRequest;
//    motionRequest.motion = MotionRequest::specialAction;
//
//    motionRequest.specialActionRequest.specialAction = SpecialActionRequest::playDead;
//
//    currentCommand = MotionCommand::ptr();
//}

void BHWalkProvider::resetOdometry() {
    walkingEngine.theOdometryData = OdometryData();
}

void BHWalkProvider::setCommand(const WalkCommand::ptr command) {

    if (command->theta_percent == 0 && command->x_percent == 0 && command->y_percent == 0) {
        this->stand();
        return;
    }

    currentCommand = command;

//    bhwalk_out << "BHWalk speed walk requested with command ";
//    bhwalk_out << *(command.get());

    active();
}

void BHWalkProvider::setCommand(const StepCommand::ptr command) {
    MotionRequest motionRequest;
    motionRequest.motion = MotionRequest::walk;
    walkingEngine.theMotionRequest = motionRequest;

    startOdometry = walkingEngine.theOdometryData;
    currentCommand = command;

//    bhwalk_out << "BHWalk step walk requested with command ";
//    bhwalk_out << *(command.get()) << endl;

    active();
}

void BHWalkProvider::setCommand(const DestinationCommand::ptr command) {

    currentCommand = command;

    active();
}

bool BHWalkProvider::calibrated() const {
    return walkingEngine.theInertiaSensorData.calibrated;
}

float BHWalkProvider::leftHandSpeed() const {
    return walkingEngine.leftHandSpeed;
}

float BHWalkProvider::rightHandSpeed() const {
    return walkingEngine.rightHandSpeed;
}

}
}
