/**
* @file InStreams.cpp
*
* Implementation of in stream classes.
*
* @author Thomas Rfer
* @author Martin Ltzsch
*/

#include <cstring>
#include <cstdlib>

#include "InStreams.h"
#include "Platform/BHAssert.h"
#include "Platform/File.h"
#include "Tools/Debugging/Debugging.h"

void StreamReader::skipData(int size, PhysicalInStream& stream)
{
  // default implementation
  char* dummy = new char[size];
  readData(dummy, size, stream);
  delete [] dummy;
}

void PhysicalInStream::skipInStream(int size)
{
  // default implementation
  char* dummy = new char[size];
  readFromStream(dummy, size);
  delete [] dummy;
}

void InText::readString(std::string& value, PhysicalInStream& stream)
{
  value = "";
  skipWhitespace(stream);
  bool containsSpaces = theChar == '"';
  if(containsSpaces && !isEof(stream))
    nextChar(stream);
  while(!isEof(stream) && (containsSpaces || !isWhitespace()) && (!containsSpaces || theChar != '"'))
  {
    if(theChar == '\\')
    {
      nextChar(stream);
      if(theChar == 'n')
        theChar = '\n';
      else if(theChar == 'r')
        theChar = '\r';
      else if(theChar == 't')
        theChar = '\t';
    }
    value += theChar;
    if(!isEof(stream))
      nextChar(stream);
  }
  if(containsSpaces && !isEof(stream))
    nextChar(stream);
  skipWhitespace(stream);
}

void InText::readData(void* p, int size, PhysicalInStream& stream)
{
  for(int i = 0; i < size; ++i)
    readChar(*((char*&) p)++, stream);
}

bool InText::isWhitespace()
{
  return theChar == ' ' || theChar == '\n' || theChar == '\r' || theChar == '\t';
}

void InText::skipWhitespace(PhysicalInStream& stream)
{
  while(!isEof(stream) && isWhitespace())
    nextChar(stream);
}

void InText::readChar(char& d, PhysicalInStream& stream)
{ readString(buf, stream); d = (char)strtol(buf.c_str(), (char**)NULL, 0); }
void InText::readUChar(unsigned char& d, PhysicalInStream& stream)
{ readString(buf, stream); d = (unsigned char)strtoul(buf.c_str(), (char**)NULL, 0); }
void InText::readShort(short& d, PhysicalInStream& stream)
{ readString(buf, stream); d = (short)strtol(buf.c_str(), (char**)NULL, 0); }
void InText::readUShort(unsigned short& d, PhysicalInStream& stream)
{readString(buf, stream); d = (unsigned short)strtoul(buf.c_str(), (char**)NULL, 0);}
void InText::readInt(int& d, PhysicalInStream& stream)
{readString(buf, stream); d = (int)strtol(buf.c_str(), (char**)NULL, 0);}
void InText::readUInt(unsigned int& d, PhysicalInStream& stream)
{readString(buf, stream); d = (unsigned int)strtoul(buf.c_str(), (char**)NULL, 0);}
void InText::readFloat(float& d, PhysicalInStream& stream)
{readString(buf, stream); d = float(atof(buf.c_str()));}
void InText::readDouble(double& d, PhysicalInStream& stream)
{readString(buf, stream); d = atof(buf.c_str());}


void InConfig::create(const std::string& sectionName, PhysicalInStream& stream)
{
  if(stream.exists() && sectionName != "")
  {
    std::string fileEntry;
    std::string section = std::string("[") + sectionName + "]";

    while(!isEof(stream))
    {
      readString(fileEntry, stream);
      if(fileEntry == section)
      {
        if(theChar == '[') // handle empty section
          while(!isEof(stream))
            InText::nextChar(stream);
        break;
      }
    }
    readSection = true;
  }
}

bool InConfig::isWhitespace()
{
  return (theChar == '/' && (theNextChar == '*' || theNextChar == '/')) ||
         theChar == '#' || InText::isWhitespace();
}

void InConfig::skipWhitespace(PhysicalInStream& stream)
{
  while(!isEof(stream) && isWhitespace())
  {
    while(!isEof(stream) && InText::isWhitespace())
      nextChar(stream);
    if(!isEof(stream))
    {
      if(theChar == '/' && theNextChar == '/')
      {
        skipLine(stream);
      }
      else if(theChar == '/' && theNextChar == '*')
      {
        skipComment(stream);
      }
      else if(theChar == '#')
      {
        skipLine(stream);
      }
    }
  }
}

void InConfig::nextChar(PhysicalInStream& stream)
{
  InText::nextChar(stream);
  if(readSection && theChar == '[')
    while(!isEof(stream))
      InText::nextChar(stream);
}

void InConfig::skipLine(PhysicalInStream& stream)
{
  while(!isEof(stream) && theChar != '\n')
    nextChar(stream);
  if(!isEof(stream))
    nextChar(stream);
}

void InConfig::skipComment(PhysicalInStream& stream)
{
  // skip /*
  nextChar(stream);
  nextChar(stream);
  while(!isEof(stream) && (theChar != '*' || theNextChar != '/'))
    nextChar(stream);

  // skip */
  if(!isEof(stream))
    nextChar(stream);
  if(!isEof(stream))
    nextChar(stream);
}

InFile::~InFile()
{ if(stream != 0) delete stream; }
bool InFile::exists() const
{ return (stream != 0 ? stream->exists() : false); }
bool InFile::getEof() const
{ return (stream != 0 ? stream->eof() : false); }
void InFile::open(const std::string& name)
{ if(stream == 0) stream = new File(name, "rb"); }
void InFile::readFromStream(void* p, int size)
{ if(stream != 0) stream->read(p, size); }

void InMemory::readFromStream(void* p, int size)
{
  if(memory != 0)
  {
    memcpy(p, memory, size);
    memory += size;
  }
}

void onError(const std::string& msg) {OUTPUT_ERROR(msg);}

InConfigMap::InConfigMap(const std::string& name, unsigned int flags) :
  flags(flags),
  name(name),
  map()
{
  stack.reserve(20);
  if(isVerbose())
  {
    status = map.read(name, true, &onError);
  }
  else
    status = map.read(name);
  map.setFlags(map.getFlags() | ConfigMap::READONLY);
}

InConfigMap::InConfigMap(const ConfigMap& map) :
  flags(OUTPUT_ERRORS),
  map(map)
{
  stack.reserve(20);
  status = 1;
}

void InConfigMap::printError(const std::string& msg)
{
  if(!doOutputErrors())
    return;

  std::string path = "";
  for(std::vector<Entry>::const_iterator i = stack.begin(); i != stack.end(); ++i)
  {
    if(i->key)
    {
      if(path != "")
        path += '.';
      path += i->key;
    }
    else
    {
      char buf[20];
      sprintf(buf, "[%d]", i->type);
      path += buf;
    }

  }
  if(name == "")
    OUTPUT_ERROR(path << ": " << msg);
  else
    OUTPUT_ERROR(name << ", " << path << ": " << msg);
}

void InConfigMap::printWarning(const std::string& msg)
{
  if(!isVerbose())
    return;

  std::string path = "";
  for(std::vector<Entry>::const_iterator i = stack.begin(); i != stack.end(); ++i)
  {
    if(i->key)
    {
      if(path != "")
        path += '.';
      path += i->key;
    }
    else
    {
      char buf[20];
      sprintf(buf, "[%d]", i->type);
      path += buf;
    }

  }
  if(name == "")
    OUTPUT_WARNING(path << ": " << msg);
  else
    OUTPUT_WARNING(name << ", " << path << ": " << msg);
}

void InConfigMap::inChar(char& value)
{
  try
  {
    Entry& e = stack.back();
    if(e.value)
    {
      int i;
      *e.value >> i;
      value = (char) i;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    if(!isTolerant())
      printError(e.what());
    else if(isVerbose())
      printWarning(e.what());
  }
}

void InConfigMap::inUChar(unsigned char& value)
{
  try
  {
    Entry& e = stack.back();
    if(e.value)
    {
      unsigned i;
      *e.value >> i;
      value = (unsigned char) i;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    if(!isTolerant())
      printError(e.what());
    else if(isVerbose())
      printWarning(e.what());
  }
}

void InConfigMap::inInt(int& value)
{
  try
  {
    Entry& e = stack.back();
    if(e.value)
    {
      if(e.enumToString)
      {
        std::string s;
        *e.value >> s;
        for(int i = 0; e.enumToString(i); ++i)
          if(s == e.enumToString(i))
          {
            value = i;
            return;
          }
        std::string t;
        for(int i = 0; e.enumToString(i); ++i)
          t += std::string("'") + e.enumToString(i) + "', ";
        printError("expected one of " + t + "found '" + s + "'");
      }
      else
        *e.value >> value;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    if(!isTolerant())
      printError(e.what());
    else if(isVerbose())
      printWarning(e.what());
  }
}

void InConfigMap::inUInt(unsigned int& value)
{
  try
  {
    Entry& e = stack.back();
    if(e.type == -1)
      value = e.value ? e.value->length() : 0;
    else if(e.value)
      *e.value >> value;
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    if(!isTolerant())
      printError(e.what());
    else if(isVerbose())
      printWarning(e.what());
  }
}

void InConfigMap::inBool(bool& value)
{
  try
  {
    Entry& e = stack.back();
    if(e.value)
    {
      std::string s;
      *e.value >> s;
      if(s == "false")
        value = false;
      else if(s == "true")
        value = true;
      else
        printError("expected 'true' or 'false', found '" + s + "'");
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    if(!isTolerant())
      printError(e.what());
    else if(isVerbose())
      printWarning(e.what());
  }
}

void InConfigMap::read(void* p, int size)
{
  ASSERT(false);
}

void InConfigMap::skip(int size)
{
  ASSERT(false);
}

void InConfigMap::select(const char* name, int type, const char * (*enumToString)(int))
{
  try
  {
    ASSERT(name || type >= 0);
    if(stack.empty())
      stack.push_back(Entry(name, &map[std::string(name)], type, enumToString));
    else if(!stack.back().value) // invalid
      stack.push_back(Entry(name, 0, type, enumToString)); // add more invalid
    else if(type >= 0)
      stack.push_back(Entry(name, &(*stack.back().value)[type], type, enumToString));
    else
      stack.push_back(Entry(name, &(*stack.back().value)[std::string(name)], type, enumToString));
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
    stack.push_back(Entry(name, 0, type, enumToString)); // add invalid
  }
  catch(invalid_key& e)
  {
    if(isTolerant())
      printWarning(e.what());
    else
      printError(e.what());
    stack.push_back(Entry(name, 0, type, enumToString)); // add invalid
  }
  catch(bad_cm_cast& e)
  {
    printError(e.what());
    stack.push_back(Entry(name, 0, type, enumToString)); // add invalid
  }
}

void InConfigMap::deselect()
{
  stack.pop_back();
}
