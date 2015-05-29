/**
* @file OutStreams.h
*
* Declaration of out stream classes for different media and formats.
*
* @author Thomas R�fer
* @author Martin L�tzsch
*/

#pragma once

#include "Tools/Streams/InOut.h"
#include "Tools/Configuration/ConfigMap.h"

class File;

/**
* @class PhysicalOutStream
*
* The base class for physical out streams. Derivates of PhysicalOutStream only handle the
* writing of data to a medium, not of formating data.
*/
class PhysicalOutStream
{
public:
  /**
  * The function writes a number of bytes into a physical stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  */
  virtual void writeToStream(const void* p, int size) = 0;

};

/**
* @class StreamWriter
*
* Generic class for formating data to be used in streams.
* The physical writing is then done by OutStream derivates.
*/
class StreamWriter
{
protected:
  /**
  * Writes a character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeChar(char d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a unsigned character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUChar(unsigned char d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeShort(short d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a unsigned short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUShort(unsigned short d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeInt(int d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a unsigned int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUInt(unsigned int d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a float to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeFloat(float d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a double to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeDouble(double d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a string to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeString(const char* d, PhysicalOutStream& stream) = 0;

  /**
  * Writes a 'end of line' to a stream.
  * @param stream the stream to write on.
  */
  virtual void writeEndL(PhysicalOutStream& stream) = 0;

  /**
  * The function writes a number of bytes into the stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  * @param stream the stream to write on.
  */
  virtual void writeData(const void* p, int size, PhysicalOutStream& stream) = 0;
};


/**
* @class OutStream
*
* Generic class for classes that do both formating and physical writing of data to streams.
*/
template <class S, class W> class OutStream : public S, public W, public Out
{
public:
  /** Standard constructor */
  OutStream() {};

  /**
  * The function writes a number of bytes into a stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  */
  virtual void write(const void* p, int size)
  { W::writeData(p, size, *this); }

protected:
  /**
  * Virtual redirection for operator<<(const char& value).
  */
  virtual void outChar(char d)
  { W::writeChar(d, *this); }

  /**
  * Virtual redirection for operator<<(const unsigned char& value).
  */
  virtual void outUChar(unsigned char d)
  { W::writeUChar(d, *this); }

  /**
  * Virtual redirection for operator<<(const short& value).
  */
  virtual void outShort(short d)
  { W::writeShort(d, *this); }

  /**
  * Virtual redirection for operator<<(const unsigned short& value).
  */
  virtual void outUShort(unsigned short d)
  { W::writeUShort(d, *this); }

  /**
  * Virtual redirection for operator<<(const int& value).
  */
  virtual void outInt(int d)
  { W::writeInt(d, *this); }

  /**
  * Virtual redirection for operator<<(const unsigned& value).
  */
  virtual void outUInt(unsigned int d)
  { W::writeUInt(d, *this); }

  /**
  * Virtual redirection for operator<<(const float& value).
  */
  virtual void outFloat(float d)
  { W::writeFloat(d, *this); }

  /**
  * Virtual redirection for operator<<(const double& value).
  */
  virtual void outDouble(double d)
  { W::writeDouble(d, *this); }

  /**
  * Virtual redirection for operator<<(const char* value).
  */
  virtual void outString(const char* d)
  { W::writeString(d, *this); }

  /**
  * Virtual redirection for operator<<(Out& (*f)(Out&)) that writes
  * the symbol "endl";
  */
  virtual void outEndL()
  { W::writeEndL(*this); }
};


/**
* @class OutBinary
*
* Formats data binary to be used in streams.
* The physical writing is then done by OutStream derivates.
*/
class OutBinary : public StreamWriter
{
protected:
  /**
  * Writes a character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeChar(char d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a unsigned character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUChar(unsigned char d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeShort(short d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a unsigned short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUShort(unsigned short d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeInt(int d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a unsigned int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUInt(unsigned int d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a float to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeFloat(float d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a double to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeDouble(double d, PhysicalOutStream& stream)
  { stream.writeToStream(&d, sizeof(d)); }

  /**
  * Writes a string to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeString(const char* d, PhysicalOutStream& stream);

  /**
  * Writes a 'end of line' to a stream.
  * @param stream the stream to write on.
  */
  virtual void writeEndL(PhysicalOutStream& stream) {};

  /**
  * The function writes a number of bytes into the stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  * @param stream the stream to write on.
  */
  virtual void writeData(const void* p, int size, PhysicalOutStream& stream)
  { stream.writeToStream(p, size); }
};

/**
* @class OutText
*
* Formats data as text to be used in streams.
* The physical writing is then done by PhysicalOutStream derivates.
*/
class OutText : public StreamWriter
{
private:
  /** A buffer for formatting the numeric data to a text format. */
  char buf[50];
protected:
  /**
  * Writes a character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeChar(char d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUChar(unsigned char d, PhysicalOutStream& stream);

  /**
  * Writes a short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeShort(short d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUShort(unsigned short d, PhysicalOutStream& stream);

  /**
  * Writes a int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeInt(int d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUInt(unsigned int d, PhysicalOutStream& stream);

  /**
  * Writes a float to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeFloat(float d, PhysicalOutStream& stream);

  /**
  * Writes a double to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeDouble(double d, PhysicalOutStream& stream);

  /**
  * Writes a string to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeString(const char* d, PhysicalOutStream& stream);

  /**
  * Writes a 'end of line' to a stream.
  * @param stream the stream to write on.
  */
  virtual void writeEndL(PhysicalOutStream& stream);

  /**
  * The function writes a number of bytes into the stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  * @param stream the stream to write on.
  */
  virtual void writeData(const void* p, int size, PhysicalOutStream& stream);
};

/**
* @class OutTextRaw
*
* Formats data as raw text to be used in streams.
* The physical writing is then done by PhysicalOutStream derivates.
* Different from OutText, OutTextRaw does not escape spaces
* and other special characters and no spaces are inserted before numbers.
* (The result of the OutTextRaw StreamWriter is the same as the result of "std::cout")
*/
class OutTextRaw : public StreamWriter
{
private:
  /** A buffer for formatting the numeric data to a text format. */
  char buf[50];
protected:
  /**
  * Writes a character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeChar(char d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned character to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUChar(unsigned char d, PhysicalOutStream& stream);

  /**
  * Writes a short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeShort(short d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned short to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUShort(unsigned short d, PhysicalOutStream& stream);

  /**
  * Writes a int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeInt(int d, PhysicalOutStream& stream);

  /**
  * Writes a unsigned int to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeUInt(unsigned int d, PhysicalOutStream& stream);

  /**
  * Writes a float to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeFloat(float d, PhysicalOutStream& stream);

  /**
  * Writes a double to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeDouble(double d, PhysicalOutStream& stream);

  /**
  * Writes a string to a stream.
  * @param d the data to write.
  * @param stream the stream to write on.
  */
  virtual void writeString(const char* d, PhysicalOutStream& stream);

  /**
  * Writes a 'end of line' to a stream.
  * @param stream the stream to write on.
  */
  virtual void writeEndL(PhysicalOutStream& stream);

  /**
  * The function writes a number of bytes into the stream.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  * @param stream the stream to write on.
  */
  virtual void writeData(const void* p, int size, PhysicalOutStream& stream);
};



/**
* @class OutFile
*
* An PhysicalOutStream that writes the data to a file.
*/
class OutFile : public PhysicalOutStream
{
private:
  File* stream; /**< Object representing the file. */

public:
  /** Default constructor */
  OutFile() : stream(0) {};

  /** Destructor */
  ~OutFile();

  /**
  * The function states whether the file actually exists.
  * @return Does the file exist?
  */
  virtual bool exists() const;

protected:
  /**
  * Opens the stream.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be discared.
  */
  void open(const std::string& name);

  /**
  * Opens the stream.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be preserved,
  *             if append = true.
  * @param append Determines, if the file content is preserved or discared.
  */
  void open(const std::string& name, bool append);

  /**
  * The function writes a number of bytes into the file.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  */
  virtual void writeToStream(const void* p, int size);
};

/**
* @class OutMemory
*
* A  PhysicalOutStream that writes the data to a memory block.
*/
class OutMemory : public PhysicalOutStream
{
private:
  char* memory; /**< Points to the next byte to write at. */
  int length; /**< The number of stored bytes */
  void* start; /**< Points to the first byte */

public:
  /** Default constructor */
  OutMemory() : memory(0), length(0), start(0) {}

  /**
  * Returns the number of written bytes
  */
  int getLength() { return length; }

  /**
  * Returns the address of the first byte
  */
  void* getMemory() { return start; }

protected:
  /**
  * opens the stream.
  * @param mem The address of the memory block into which is written.
  */
  void open(void* mem)
  { memory = (char*)mem; start = mem; length = 0;}

  /**
  * The function writes a number of bytes into memory.
  * @param p The address the data is located at.
  * @param size The number of bytes to be written.
  */
  virtual void writeToStream(const void* p, int size);
};

/**
* @class OutSize
*
* A PhysicalOutStream that doesn't write any data. Instead it works as a
* counter that determines how many bytes would be streamed into memory.
* It can be used to determine the size of the memory block that is
* required as the parameter for an instance of class OutMemoryStream.
*/
class OutSize : public PhysicalOutStream
{
private:
  unsigned size; /**< Accumulator of the required number of bytes. */

public:
  /**
  * The function resets the counter to zero.
  */
  void reset() {size = 0;}

  /**
  * Constructor.
  */
  OutSize() {reset();}

  /**
  * The function returns the number of bytes required to store the
  * data written so far.
  * @return The size of the memory block required for the data written.
  */
  unsigned getSize() const {return size;}

protected:
  /**
  * The function counts the number of bytes that should be written.
  * @param p The address the data is located at.
  * @param s The number of bytes to be written.
  */
  virtual void writeToStream(const void* p, int s) {size += s;}
};

/**
* @class OutBinaryFile
*
* A binary stream into a file.
*/
class OutBinaryFile : public OutStream<OutFile, OutBinary>
{
public:
  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be discared.
  */
  OutBinaryFile(const std::string& name)
  { open(name); }

  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be preserved,
  *             if append = true.
  * @param append Determines, if the file content is preserved or discared.
  */
  OutBinaryFile(const std::string& name, bool append)
  { open(name, append); }

  /**
  * The function returns whether this is a binary stream.
  * @return Does it output data in binary format?
  */
  virtual bool isBinary() const {return true;}
};

/**
* @class OutBinaryMemory
*
* A binary stream into a memory region.
*/
class OutBinaryMemory : public OutStream<OutMemory, OutBinary>
{
public:
  /**
  * Constructor.
  * @param mem The address of the memory block into which is written.
  */
  OutBinaryMemory(void* mem)
  { open(mem); }

  /**
  * The function returns whether this is a binary stream.
  * @return Does it output data in binary format?
  */
  virtual bool isBinary() const {return true;}
};

/**
* @class OutBinarySize
*
* A binary stream size counter
*/
class OutBinarySize : public OutStream<OutSize, OutBinary>
{
public:
  /**
  * Constructor.
  */
  OutBinarySize() {}

  /**
  * The function returns whether this is a binary stream.
  * @return Does it output data in binary format?
  */
  virtual bool isBinary() const {return true;}
};

/**
* @class OutTextFile
*
* A text stream into a file.
*/
class OutTextFile : public OutStream<OutFile, OutText>
{
public:
  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be discared.
  */
  OutTextFile(const std::string& name)
  { open(name); }

  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be preserved,
  *             if append = true.
  * @param append Determines, if the file content is preserved or discared.
  */
  OutTextFile(const std::string& name, bool append)
  { open(name, append); }
};

/**
* @class OutTextRawFile
*
* A text stream into a file.
*/
class OutTextRawFile : public OutStream<OutFile, OutTextRaw>
{
public:
  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be discared.
  */
  OutTextRawFile(const std::string& name)
  { open(name); }

  /**
  * Constructor.
  * @param name The name of the file to open. It will be interpreted
  *             as relative to the configuration directory. If the file
  *             does not exist, it will be created. If it already
  *             exists, its previous contents will be preserved,
  *             if append = true.
  * @param append Determines, if the file content is preserved or discared.
  */
  OutTextRawFile(const std::string& name, bool append)
  { open(name, append); }
};

/**
* @class OutTextMemory
*
* A text stream into a memory region.
*/
class OutTextMemory : public OutStream<OutMemory, OutText>
{
public:
  /**
  * Constructor.
  * @param mem The address of the memory block into which is written.
  */
  OutTextMemory(void* mem)
  { open(mem); }
};

/**
* @class OutTextRawMemory
*
* A text stream into a memory region.
*/
class OutTextRawMemory : public OutStream<OutMemory, OutTextRaw>
{
public:
  /**
  * Constructor.
  * @param mem The address of the memory block into which is written.
  */
  OutTextRawMemory(void* mem)
  { open(mem); }
};

/**
* @class OutTextSize
*
* A Text stream size counter
*/
class OutTextSize : public OutStream<OutSize, OutText>
{
public:
  /**
  * Constructor.
  */
  OutTextSize() {}
};

/**
* @class OutTextRawSize
*
* A Text stream size counter
*/
class OutTextRawSize : public OutStream<OutSize, OutTextRaw>
{
public:
  /**
  * Constructor.
  */
  OutTextRawSize() {}
};

class OutConfigMap : public Out
{
  /**
  * An entry representing a position in the ConfigMap.
  */
  class Entry
  {
  public:
    const char* key; /**< The name of the current key (used by printError()). */
    int type; /**< The type of the entry. -2: value or record, -1: array or list, >= 0: array/list element index. */
    const char* (*enumToString)(int); /**< A function that translates an enum to a string. */

    Entry(const char* key, int type, const char * (*enumToString)(int)) :
      key(key), type(type), enumToString(enumToString) {}
  };
  std::string* name; /**< The name of the opened file. */
  ConfigMap* map;
  std::vector<Entry> stack; /**< The hierarchy of values to read. */
  
  /**
  * The method OUTPUTs an error message.
  * @param msg The error message.
  */
  void printError(const std::string& msg);
  
public:
  OutConfigMap(ConfigMap& map);
  OutConfigMap(const std::string& filename);
  ~OutConfigMap();
  template<class T> void out(const T& value)
  {
    Entry e = stack.back();
    try
    {
      if(e.type > -3)
        (*map)[e.key] << value;
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
  virtual void outChar(char value);
  virtual void outUChar(unsigned char value);
  virtual void outShort(short value) {out(value);}
  virtual void outUShort(unsigned short value) {out(value);}
  virtual void outInt(int value);
  virtual void outUInt(unsigned int value);
  virtual void outFloat(float value) {out(value);}
  virtual void outDouble(double value) {out(value);}
  virtual void outString(const char* value) {out(value);}
  virtual void outEndL() {}
  virtual void select(const char* name, int type, const char * (*enumToString)(int) = 0);
  virtual void deselect();
  virtual void write();
  virtual void write(const void* p, int size) {}
  virtual bool exists() const;
};
