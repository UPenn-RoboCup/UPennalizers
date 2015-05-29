/**
* @file WalkingEngineKick.cpp
* Implementation of class WalkingEngineKick
* @author Colin Graf
*/

#include <cstring>

#include "WalkingEngineKick.h"
#include "Platform/File.h"

bool WalkingEngineKick::String::operator==(const WalkingEngineKick::String& other) const
{
  return other.len == len && memcmp(other.ptr, ptr, len) == 0;
}

WalkingEngineKick::String WalkingEngineKick::readString(char*& buf)
{
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  char* result = buf;
  while(isalnum(*buf))
    ++buf;
  if(buf == result || (*buf && *buf != ' ' && *buf != '\t' && *buf != '\r' && *buf != '\n'))
    throw ParseException("expected string");
  return String(result, buf - result);
}

unsigned int WalkingEngineKick::readUInt(char*& buf)
{
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  char* result = buf;
  if(*buf == '-')
    ++buf;
  while(isdigit(*buf))
    ++buf;
  if(buf == result || (*buf && *buf != ' ' && *buf != '\t' && *buf != '\r' && *buf != '\n'))
    throw ParseException("expected integer");
  char c = *buf;
  *buf = '\0';
  int i = atoi(result);
  *buf = c;
  return (unsigned int)i;
}

float WalkingEngineKick::readFloat(char*& buf)
{
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  char* result = buf;
  if(*buf == '-')
    ++buf;
  while(isdigit(*buf))
    ++buf;
  if(buf == result)
    throw ParseException("expected float");
  if(*buf == '.')
  {
    ++buf;
    while(isdigit(*buf))
      ++buf;
    if(*buf && *buf != ' ' && *buf != '\t' && *buf != '\r' && *buf != '\n')
      throw ParseException("expected float");
  }
  char c = *buf;
  *buf = '\0';
  float f = float(atof(result));
  *buf = c;
  return f;
}

WalkingEngineKick::Value* WalkingEngineKick::readValue(char*& buf)
{
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  switch(*buf)
  {
  case '(':
  {
    ++buf;
    Value* result = readPlusFormula(buf);
    while(*buf == ' ' || *buf == '\t')
      ++buf;
    if(*buf != ')')
      throw ParseException("expected ')'");
    ++buf;
    return result;
  }
  case '$':
  {
    ++buf;
    unsigned int i = readUInt(buf);
    return new ParameterValue(i, *this);
  }
  default:
  {
    float f = readFloat(buf);
    return new ConstantValue(f, *this);
  }
  }
}

WalkingEngineKick::Value* WalkingEngineKick::readPlusFormula(char*& buf)
{
  Value* value1 = readMultFormula(buf);
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  while(*buf == '+' || *buf == '-')
  {
    char c = *(buf++);
    Value* value2 = readMultFormula(buf);
    Value* value;
    if(c == '+')
      value = new PlusExpression(*value1, *value2, *this);
    else
      value = new MinusExpression(*value1, *value2, *this);
    value1 = value;
  }
  return value1;
}

WalkingEngineKick::Value* WalkingEngineKick::readMultFormula(char*& buf)
{
  Value* value1 = readValue(buf);
  while(*buf == ' ' || *buf == '\t')
    ++buf;
  while(*buf == '*' || *buf == '/')
  {
    char c = *(buf++);
    Value* value2 = readValue(buf);
    Value* value;
    switch(c)
    {
    case '*':
      value = new TimesExpression(*value1, *value2, *this);
      break;
    case '/':
      value = new DivExpression(*value1, *value2, *this);
      break;
    default:
      value = 0;
      ASSERT(false);
      break;
    }
    value1 = value;
  }
  return value1;
}

bool WalkingEngineKick::load(const char* filePath, char* buf)
{
  initialized = false;

  int lineNumber = 0;
  bool error = false;

  for(int i = 0; i < numOfTracks; ++i)
  {
    tracks[i].clear();
    addPhase(Track(i), 0);
  }

  while(*buf)
  {
    ++lineNumber;

    try
    {
      while(*buf == ' ' || *buf == '\t')
        ++buf;

      if(*buf != '#' && *buf != ';' && *buf != '\r' && *buf != '\n')
      {
        String str = readString(buf);
        if(str == "setType")
        {
          String str = readString(buf);
          if(str == "standing")
            standKick = true;
          else if(str == "walking")
            standKick = false;
          else
            throw ParseException("expected 'standing' or 'walking'");
        }
        else if(str == "setPreStepSize")
        {
          preStepSizeXValue = readValue(buf);
          preStepSizeYValue = readValue(buf);
          preStepSizeZValue = readValue(buf);
          readValue(buf);
          readValue(buf);
          preStepSizeRValue = readValue(buf);
        }
        else if(str == "setStepSize")
        {
          stepSizeXValue = readValue(buf);
          stepSizeYValue = readValue(buf);
          stepSizeZValue = readValue(buf);
          readValue(buf);
          readValue(buf);
          stepSizeRValue = readValue(buf);
        }
        else if(str == "setDuration")
        {
          durationValue = readValue(buf);
        }
        else if(str == "setRefX")
        {
          refXValue = readValue(buf);
        }
        else if(str == "proceed")
        {
          Value* value = readValue(buf);
          for(int i = 0; i < numOfTracks; ++i)
          {
            Phase& lastPhase = tracks[i].back();
            if(!lastPhase.lengthValue)
              lastPhase.lengthValue = value;
            else
              lastPhase.lengthValue = new PlusExpression(*lastPhase.lengthValue, *value, *this);
          }
        }
        else if(str == "setLeg")
        {
          addPhase(footTranslationX, readValue(buf));
          addPhase(footTranslationY, readValue(buf));
          addPhase(footTranslationZ, readValue(buf));
          addPhase(footRotationX, readValue(buf));
          addPhase(footRotationY, readValue(buf));
          addPhase(footRotationZ, readValue(buf));
        }
        else if(str == "setArms")
        {
          addPhase(lShoulderPitch, readValue(buf));
          addPhase(lShoulderRoll, readValue(buf));
          addPhase(lElbowYaw, readValue(buf));
          addPhase(lElbowRoll, readValue(buf));
          addPhase(rShoulderPitch, readValue(buf));
          addPhase(rShoulderRoll, readValue(buf));
          addPhase(rElbowYaw, readValue(buf));
          addPhase(rElbowRoll, readValue(buf));
        }
        else if(str == "setHead")
        {
          addPhase(headYaw, readValue(buf));
          addPhase(headPitch, readValue(buf));
        }
        else
          throw ParseException("expected keyword");

        while(*buf == ' ' || *buf == '\t')
          ++buf;
      }

      if(*buf == '#' || *buf == ';')
      {
        ++buf;
        while(*buf && *buf != '\r' && *buf != '\n')
          ++buf;
      }

      if(*buf && *buf != '\r' && *buf != '\n')
        throw ParseException("expected end of line");
    }
    catch(ParseException e)
    {
//      OUTPUT(idText, text, filePath << ":" << lineNumber << ": " << e.message);
      (void)e;
      error = true;
    }

    while(*buf && *buf != '\r' && *buf != '\n')
      ++buf;
    if(*buf == '\r' && buf[1] == '\n')
      buf += 2;
    else if(*buf)
      ++buf;
  }

  if(error)
  {
    for(int i = 0; i < numOfTracks; ++i)
      tracks[i].clear();
//    OUTPUT(idText, text, filePath << ": failed to load file");
    return false;
  }

  for(int i = 0; i < numOfTracks; ++i)
    addPhase(Track(i), 0);

  return true;
}

bool WalkingEngineKick::load(const char* filePath)
{
  File file(filePath, "rb");
  bool success = file.exists();
  if(success)
  {
    int size = file.getSize();
    char* buffer = new char[size + 1];
    file.read(buffer, size);
    buffer[size] = '\0';
    success = load(filePath, buffer);
    delete[] buffer;
  }
  return success;
}

WalkingEngineKick::WalkingEngineKick() : initialized(false), firstValue(0), standKick(false),
  preStepSizeRValue(0), preStepSizeXValue(0), preStepSizeYValue(0), preStepSizeZValue(0),
  stepSizeRValue(0), stepSizeXValue(0), stepSizeYValue(0), stepSizeZValue(0), durationValue(0), refXValue(0) {}

WalkingEngineKick::~WalkingEngineKick()
{
  for(Value * nextValue; firstValue; firstValue = nextValue)
  {
    nextValue = firstValue->next;
    delete firstValue;
  }
}

void WalkingEngineKick::addPhase(Track track, Value* value)
{
  tracks[track].push_back(Phase(value));
}

void WalkingEngineKick::init()
{
  const bool precomputeLength = !standKick;
  length = -1.f;
  for(int i = 0; i < numOfTracks; ++i)
  {
    currentPhases[i] = -1;
    if(precomputeLength)
    {
      std::vector<Phase>& phases = tracks[i];
      float pos = 0.f;
      for(int i = 0, end = phases.size(); i < end; ++i)
      {
        Phase& phase = phases[i];
        phase.evaluateLength(pos);
        pos = phase.end;
      }
      if(pos > length)
        length = pos;
    }
  }
  currentPosition = 0.f;
  initialized = true;
}

void WalkingEngineKick::getPreStepSize(float& rotation, Vector3<>& translation) const
{
  rotation = preStepSizeRValue ? preStepSizeRValue->evaluate() : 0.f;
  translation.x = preStepSizeXValue ? preStepSizeXValue->evaluate() : 0.f;
  translation.y = preStepSizeYValue ? preStepSizeYValue->evaluate() : 0.f;
  translation.z = preStepSizeZValue ? preStepSizeZValue->evaluate() : 0.f;
}

void WalkingEngineKick::getStepSize(float& rotation, Vector3<>& translation) const
{
  rotation = stepSizeRValue ? stepSizeRValue->evaluate() : 0.f;
  translation.x = stepSizeXValue ? stepSizeXValue->evaluate() : 0.f;
  translation.y = stepSizeYValue ? stepSizeYValue->evaluate() : 0.f;
  translation.z = stepSizeZValue ? stepSizeZValue->evaluate() : 0.f;
}

float WalkingEngineKick::getDuration() const
{
  return durationValue ? durationValue->evaluate() * 0.001f : 0.f;
}

float WalkingEngineKick::getRefX(float defaultValue) const
{
  return refXValue ? refXValue->evaluate() : defaultValue;
}

void WalkingEngineKick::setParameters(const Vector2<>& ballPosition, const Vector2<>& target)
{
  this->ballPosition = ballPosition;
  this->target = target;
}

bool WalkingEngineKick::seek(float s)
{
  if(!initialized)
    return false;
  currentPosition += s * 1000.f;
  std::vector<Phase>& phases = tracks[0];
  int preLastPhase = phases.size() - 2;
  return currentPhases[0] < preLastPhase || currentPosition < phases.back().start;
}

float WalkingEngineKick::getValue(Track track, float externValue)
{
  std::vector<Phase>& phases = tracks[track];
  const int phasesSize = int(phases.size());
  int currentPhase = currentPhases[track];

  const bool init = currentPhase < 0;
  if(init)
    currentPhase = currentPhases[track] = 0;

  ASSERT(currentPhase < phasesSize - 1);
  Phase* phase = &phases[currentPhase];
  Phase* nextPhase = &phases[currentPhase + 1];

  if(init)
  {
    const bool precomputedLength = length >= 0.f;
    if(!precomputedLength)
    {
      phase->evaluateLength(0.f);
      nextPhase->evaluateLength(phase->end);
    }
    phase->evaluatePos(externValue);
    nextPhase->evaluatePos(externValue);
    Phase* const nextNextPhase = currentPhase + 2 < phasesSize ? &phases[currentPhase + 2] : 0;
    if(nextNextPhase)
    {
      if(!precomputedLength)
        nextNextPhase->evaluateLength(nextPhase->end);
      nextNextPhase->evaluatePos(externValue);
      nextPhase->velocity = ((nextPhase->pos - phase->pos) / phase->length + (nextNextPhase->pos - nextPhase->pos) / nextPhase->length) * 0.5f;
    }
  }

  while(phase->end <= currentPosition)
  {
    Phase* nextNextPhase = currentPhase + 2 < phasesSize ? &phases[currentPhase + 2] : 0;
    if(!nextNextPhase)
    {
      ASSERT(nextPhase->posValue == 0);
      return externValue;
    }

    currentPhase = ++currentPhases[track];
    phase = nextPhase;
    nextPhase = nextNextPhase;
    if(currentPhase + 2 < phasesSize)
    {
      nextNextPhase = &phases[currentPhase + 2];
      const bool precomputedLength = length >= 0.f;
      if(!precomputedLength)
        nextNextPhase->evaluateLength(nextPhase->end);
      nextNextPhase->evaluatePos(externValue);
      nextPhase->velocity = ((nextPhase->pos - phase->pos) / phase->length + (nextNextPhase->pos - nextPhase->pos) / nextPhase->length) * 0.5f;
    }
  }

  if(!phase->posValue)
    phase->pos = externValue;
  if(!nextPhase->posValue)
    nextPhase->pos = externValue;

  const float nextRatio = (currentPosition - phase->start) / phase->length;
  const float d = phase->pos;
  const float c = phase->velocity;
  const float v2 = nextPhase->velocity;
  const float p2 = nextPhase->pos;
  const float p2mcmd = p2 - c - d;
  const float a = -2.f * p2mcmd + (v2 - c);
  const float b = p2mcmd - a;
  const float x = nextRatio;
  const float xx = x * x;
  return a * xx * x + b * xx + c * x + d;
}
