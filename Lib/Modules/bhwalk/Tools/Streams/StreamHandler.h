
#pragma once

#include <vector>
#include <stack>
#ifdef __APPLE__
/* For clang
http://clang.llvm.org/docs/ClangTools.html
*/
#include <unordered_map>
#else
#include <tr1/unordered_map>
#endif
#include "Tools/Streams/OutStreams.h"

class StreamHandler;

In& operator>>(In& in, StreamHandler& streamHandler);
Out& operator<<(Out& out, const StreamHandler& streamHandler);

class ConsoleRoboCupCtrl;
class RobotConsole;
class Framework;

/**
* singleton stream handler class
*/
class StreamHandler
{
private:
  /**
   * Default constructor.
   * No other instance of this class is allowed except the one accessible via getStreamHandler
   * therefore the constructor is private.
   */
  StreamHandler();

  /**
   * Copy constructor.
   * Copying instances of this class is not allowed
   * therefore the copy constructor is private. */
  StreamHandler(const StreamHandler&) {}

  /*
  * only a process is allowed to create the instance.
  */
  friend class Process;

  struct RegisteringAttributes
  {
    short baseClass;
    bool registering;
    bool externalOperator;
  };

  typedef std::pair< std::string, const char*> TypeNamePair;

#ifdef __APPLE__
  typedef std::unordered_map<const char*, const char*> BasicTypeSpecification;
  typedef std::unordered_map<const char*, std::vector<TypeNamePair> > Specification;
  typedef std::unordered_map<const char*, std::vector<const char*> > EnumSpecification;  
  typedef std::unordered_map<std::string, int> StringTable;
#else
  typedef std::tr1::unordered_map<const char*, const char*> BasicTypeSpecification;
  typedef std::tr1::unordered_map<const char*, std::vector<TypeNamePair> > Specification;
  typedef std::tr1::unordered_map<const char*, std::vector<const char*> > EnumSpecification;  
  typedef std::tr1::unordered_map<std::string, int> StringTable;
#endif
  
  BasicTypeSpecification basicTypeSpecification;
  Specification specification;
  EnumSpecification enumSpecification;
  StringTable stringTable;

  typedef std::pair<Specification::iterator, RegisteringAttributes> RegisteringEntry;
  typedef std::stack<RegisteringEntry> RegisteringEntryStack;
  RegisteringEntryStack registeringEntryStack;

  bool registering;
  bool registeringBase;

  const char* getString(const std::string& string);

public:
  void clear();
  void startRegistration(const char* name, bool registerWithExternalOperator);
  void registerBase() {registeringBase = true;}
  void finishRegistration();
  void registerWithSpecification(const char* name, const std::type_info& ti);
  void registerEnum(const std::type_info& ti, const char* (*fp)(int));
  OutBinarySize dummyStream;

private:
  friend In& operator>>(In&, StreamHandler&);
  friend Out& operator<<(Out&, const StreamHandler&);
  friend class ConsoleRoboCupCtrl;
  friend class RobotConsole;
  friend class TeamComm3DCtrl;
  friend class Framework;
};
