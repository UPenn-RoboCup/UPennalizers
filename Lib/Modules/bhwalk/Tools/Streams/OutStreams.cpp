/**
* @file OutStreams.cpp
*
* Implementation of out stream classes.
*
* @author Thomas Röfer
* @author Martin Lötzsch
*/

#include <cstdio>
#include <cstring>

#include "OutStreams.h"
#include "Platform/File.h"
#include "Platform/BHAssert.h"
#include "Tools/Debugging/Debugging.h"

void OutBinary::writeString(const char* d, PhysicalOutStream& stream)
{ int size = (int)strlen(d); stream.writeToStream(&size, sizeof(size)); stream.writeToStream(d, size);}


void OutText::writeString(const char* value, PhysicalOutStream& stream)
{
  stream.writeToStream(" ", 1);
  bool containsSpaces = !*value || *value == '"' || strcspn(value, " \n\r\t") < strlen(value);
  if(containsSpaces)
    stream.writeToStream("\"", 1);
  for(; *value; ++value)
    if(*value == '"' && containsSpaces)
      stream.writeToStream("\\\"", 2);
    else if(*value == '\n')
      stream.writeToStream("\\n", 2);
    else if(*value == '\r')
      stream.writeToStream("\\r", 2);
    else if(*value == '\t')
      stream.writeToStream("\\t", 2);
    else if(*value == '\\')
      stream.writeToStream("\\\\", 2);
    else
      stream.writeToStream(value, 1);
  if(containsSpaces)
    stream.writeToStream("\"", 1);
}

void OutText::writeData(const void* p, int size, PhysicalOutStream& stream)
{
  for(int i = 0; i < size; ++i)
    writeChar(*((const char*&) p)++, stream);
}

void OutText::writeChar(char d, PhysicalOutStream& stream)
{ sprintf(buf, " %d", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeUChar(unsigned char d, PhysicalOutStream& stream)
{ sprintf(buf, " %u", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeShort(short d, PhysicalOutStream& stream)
{ sprintf(buf, " %d", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeUShort(unsigned short d, PhysicalOutStream& stream)
{ sprintf(buf, " %u", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeInt(int d, PhysicalOutStream& stream)
{ sprintf(buf, " %d", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeUInt(unsigned int d, PhysicalOutStream& stream)
{ sprintf(buf, " %u", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeFloat(float d, PhysicalOutStream& stream)
{ sprintf(buf, " %g", double(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeDouble(double d, PhysicalOutStream& stream)
{ sprintf(buf, " %g", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutText::writeEndL(PhysicalOutStream& stream)
{ sprintf(buf, "\r\n"); stream.writeToStream(buf, (int)strlen(buf)); }


void OutTextRaw::writeString(const char* value, PhysicalOutStream& stream)
{
  stream.writeToStream(value, (int)strlen(value));
}

void OutTextRaw::writeData(const void* p, int size, PhysicalOutStream& stream)
{
  for(int i = 0; i < size; ++i)
    writeChar(*((const char*&) p)++, stream);
}

void OutTextRaw::writeChar(char d, PhysicalOutStream& stream)
{ sprintf(buf, "%d", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeUChar(unsigned char d, PhysicalOutStream& stream)
{ sprintf(buf, "%u", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeShort(short d, PhysicalOutStream& stream)
{ sprintf(buf, "%d", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeUShort(unsigned short d, PhysicalOutStream& stream)
{ sprintf(buf, "%u", int(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeInt(int d, PhysicalOutStream& stream)
{ sprintf(buf, "%d", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeUInt(unsigned int d, PhysicalOutStream& stream)
{ sprintf(buf, "%u", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeFloat(float d, PhysicalOutStream& stream)
{ sprintf(buf, "%g", double(d)); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeDouble(double d, PhysicalOutStream& stream)
{ sprintf(buf, "%g", d); stream.writeToStream(buf, (int)strlen(buf)); }
void OutTextRaw::writeEndL(PhysicalOutStream& stream)
{ sprintf(buf, "\r\n"); stream.writeToStream(buf, (int)strlen(buf)); }


OutFile::~OutFile()
{ if(stream != 0) delete stream; }
bool OutFile::exists() const
{return (stream != 0 ? stream->exists() : false);}
void OutFile::open(const std::string& name)
{ stream = new File(name, "wb"); }
void OutFile::open(const std::string& name, bool append)
{ stream = append ? new File(name, "ab") : new File(name, "wb");}
void OutFile::writeToStream(const void* p, int size)
{ if(stream != 0) stream->write(p, size); }

void OutMemory::writeToStream(const void* p, int size)
{ if(memory != 0) { memcpy(memory, p, size); memory += size; length += size; } }

OutConfigMap::OutConfigMap(ConfigMap& map)
  : name(0),
    map(&map)
{ }

OutConfigMap::OutConfigMap(const std::string& filename)
  : name(new std::string(filename)),
    map(new ConfigMap())
{ }

OutConfigMap::~OutConfigMap()
{
  if(name)
  {
    delete name;
    delete map;
  }
}

void OutConfigMap::outChar(char value)
{
  try
  {
    Entry e = stack.back();
    if(e.type > -3)
    {
      int i = static_cast<int>(value);
      (*map)[e.key] << i;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    printError(e.what());
  }
}

void OutConfigMap::outUChar(unsigned char value)
{
  try
  {
    Entry e = stack.back();
    if(e.type > -3)
    {
      unsigned i = static_cast<unsigned>(value);
      (*map)[e.key] << i;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    printError(e.what());
  }
}

void OutConfigMap::outInt(int value)
{
  try
  {
    Entry e = stack.back();
    if(e.type > -3)
    {
      if(e.enumToString)
        (*map)[e.key] << std::string(e.enumToString(value));
      else
        (*map)[e.key] << value;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    printError(e.what());
  }
}

void OutConfigMap::outUInt(unsigned int value)
{
  try
  {
    Entry e = stack.back();
    if(e.type > -3)
    {
      if(e.type == -1)
        (*map)[e.key] = ListConfigValue();
      else
        (*map)[e.key] << value;
    }
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
  }
  catch(invalid_key& e)
  {
    printError(e.what());
  }
}

void OutConfigMap::select(const char* name, int type, const char * (*enumToString)(int))
{
  try
  {
    ASSERT(name || type >= 0);
    std::stringstream buf;
    if(!stack.empty())
    {
      Entry e = stack.back();
      if(e.type < -2)  // invalid
      {
        stack.push_back(Entry(name, -3, enumToString));
        return;
      }
      buf << e.key << ".";
    }

    if(type >= 0)
      buf << type;
    else
      buf << name;
#ifdef WIN32
    stack.push_back(Entry(_strdup(buf.str().c_str()), type, enumToString));
#else
    stack.push_back(Entry(strdup(buf.str().c_str()), type, enumToString));
#endif // WIN32
  }
  catch(std::invalid_argument& e)
  {
    printError(e.what());
    stack.push_back(Entry(name, -3, enumToString)); // add invalid
  }
  catch(invalid_key& e)
  {
    printError(e.what());
    stack.push_back(Entry(name, -3, enumToString)); // add invalid
  }
}
void OutConfigMap::deselect()
{
  stack.pop_back();
}

void OutConfigMap::write()
{
  map->write(name);
}

void OutConfigMap::printError(const std::string& msg)
{
  if(name)
    OUTPUT_ERROR(*name << ", " << stack.back().key << ": " << msg);
  else
    OUTPUT_ERROR(stack.back().key << ": " << msg);
}

bool OutConfigMap::exists() const
{
  if(!name)
    return true;
  File f(*name, "w");
  return f.exists();
}
