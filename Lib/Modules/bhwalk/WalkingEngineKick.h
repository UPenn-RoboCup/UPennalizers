/**
* @file WalkingEngineKick.h
* Declaration of class WalkingEngineKick
* @author Colin Graf
*/

#pragma once

#include "Tools/Math/Vector2.h"
#include "Tools/Math/Vector3.h"
#include "Representations/Infrastructure/JointData.h"

class WalkingEngineKick
{
public:
  enum Track
  {
    headYaw = JointData::HeadYaw,
    headPitch = JointData::HeadPitch,
    lShoulderPitch = JointData::LShoulderPitch,
    lShoulderRoll = JointData::LShoulderRoll,
    lElbowYaw = JointData::LElbowYaw,
    lElbowRoll = JointData::LElbowRoll,
    rShoulderPitch = JointData::RShoulderPitch,
    rShoulderRoll = JointData::RShoulderRoll,
    rElbowYaw = JointData::RElbowYaw,
    rElbowRoll = JointData::RElbowRoll,
    numOfJointTracks,
    footTranslationX = numOfJointTracks,
    footTranslationY,
    footTranslationZ,
    footRotationX,
    footRotationY,
    footRotationZ,
    numOfTracks,
  };

  WalkingEngineKick();
  ~WalkingEngineKick();

  bool load(const char* filePath);
  bool load(const char* filePath, char* data);
  void init();
  void getPreStepSize(float& rotation, Vector3<>& translation) const;
  void getStepSize(float& rotation, Vector3<>& translation) const;
  float getDuration() const;
  float getRefX(float defaultValue) const;
  void setParameters(const Vector2<>& ballPosition, const Vector2<>& target);
  bool seek(float s);
  float getValue(Track track, float externValue);
  float getLength() const {return length * 0.001f;}
  float getCurrentPosition() const {return currentPosition * 0.001f;}
  bool isStandKick() const {return standKick;}

private:
  class String
  {
  public:
    template<int N>String(const char(&ptr)[N]) : ptr(ptr), len(N - 1) {}
    String(const char* ptr, unsigned int len) : ptr(ptr), len(len) {}
    bool operator==(const String& other) const;
  private:
    const char* ptr;
    unsigned int len;
  };

  class Value
  {
  public:
    Value(WalkingEngineKick& kick) : next(kick.firstValue) {kick.firstValue = this;}

    virtual float evaluate() const = 0;

  protected:
    float value;

  private:
    Value* next;

    friend class WalkingEngineKick;
  };

  class ConstantValue : public Value
  {
  public:
    ConstantValue(float value, WalkingEngineKick& kick) : Value(kick) {this->value = value;}

  private:
    virtual float evaluate() const {return value;}
  };

  class BinaryExpression : public Value
  {
  public:
    BinaryExpression(Value& operand1, Value& operand2, WalkingEngineKick& kick) : Value(kick), operand1(operand1), operand2(operand2) {}

  protected:
    Value& operand1;
    Value& operand2;
  };

  class PlusExpression : public BinaryExpression
  {
  public:
    PlusExpression(Value& operand1, Value& operand2, WalkingEngineKick& kick) : BinaryExpression(operand1, operand2, kick) {}

  private:
    virtual float evaluate() const {return operand1.evaluate() + operand2.evaluate();}
  };

  class MinusExpression : public BinaryExpression
  {
  public:
    MinusExpression(Value& operand1, Value& operand2, WalkingEngineKick& kick) : BinaryExpression(operand1, operand2, kick) {}

  private:
    virtual float evaluate() const {return operand1.evaluate() - operand2.evaluate();}
  };

  class TimesExpression : public BinaryExpression
  {
  public:
    TimesExpression(Value& operand1, Value& operand2, WalkingEngineKick& kick) : BinaryExpression(operand1, operand2, kick) {}

  private:
    virtual float evaluate() const {return operand1.evaluate() * operand2.evaluate();}
  };

  class DivExpression : public BinaryExpression
  {
  public:
    DivExpression(Value& operand1, Value& operand2, WalkingEngineKick& kick) : BinaryExpression(operand1, operand2, kick) {}

  private:
    virtual float evaluate() const {return operand1.evaluate() / operand2.evaluate();}
  };

  class ParameterValue : public Value
  {
  public:
    ParameterValue(unsigned int index, WalkingEngineKick& kick) : Value(kick), index(index), kick(kick) {}

  private:
    unsigned int index;
    WalkingEngineKick& kick;

    virtual float evaluate() const {return kick.getParameterValue(index);}
  };

  class ParseException
  {
  public:
    ParseException(const char* message) : message(message) {}
    const char* message;
  };

  class Phase
  {
  public:
    Value* posValue;
    Value* lengthValue;
    float pos;
    float velocity;
    float start;
    float end;
    float length;

    Phase(Value* pos) : posValue(pos), lengthValue(0), velocity(0) {}

    void evaluateLength(float start)
    {
      length = lengthValue ? lengthValue->evaluate() : 0.f;
      this->start = start;
      end = start + length;
    }

    void evaluatePos(float externValue)
    {
      pos = posValue ? posValue->evaluate() : externValue;
    }
  };

  bool initialized;
  Value* firstValue;

  bool standKick;
  Value* preStepSizeRValue;
  Value* preStepSizeXValue;
  Value* preStepSizeYValue;
  Value* preStepSizeZValue;
  Value* stepSizeRValue;
  Value* stepSizeXValue;
  Value* stepSizeYValue;
  Value* stepSizeZValue;
  Value* durationValue;
  Value* refXValue;
  std::vector<Phase> tracks[numOfTracks];
  int currentPhases[numOfTracks];
  float currentPosition;
  float length;

  Vector2<> ballPosition;
  Vector2<> target;

  inline float getParameterValue(unsigned int index) {return index < 2 ? ballPosition[index] : index < 4 ? target[index - 2] : 0;}

  void addPhase(Track track, Value* value);

  String readString(char*& buf);
  unsigned int readUInt(char*& buf);
  float readFloat(char*& buf);
  Value* readValue(char*& buf);
  Value* readPlusFormula(char*& buf);
  Value* readMultFormula(char*& buf);
};
