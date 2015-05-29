/**
* @file Global.h
* Declaration of a class that contains pointers to global data.
* @author <a href="mailto:Thomas.Roefer@dfki.de">Thomas Röfer</a>
*/

#pragma once

#define PROCESS_WIDE_STORAGE(type) __thread type*
#define PROCESS_WIDE_STORAGE_STATIC(type) static PROCESS_WIDE_STORAGE(type)

//#include "Platform/SystemCall.h"

// Only declare prototypes. Don't include anything here, because this
// file is included in many other files.
class OutMessage;
class Settings;
class DebugRequestTable;
class DebugDataTable;
class StreamHandler;
class DrawingManager;
class DrawingManager3D;
class ReleaseOptions;

class Process;
class Cognition;
class ConsoleRoboCupCtrl;
class RobotConsole;
class TeamComm3DCtrl;
class Framework;

/**
* @class Global
* A class that contains pointers to global data.
*/
class Global
{
private:
  PROCESS_WIDE_STORAGE_STATIC(OutMessage) theDebugOut;
  PROCESS_WIDE_STORAGE_STATIC(OutMessage) theTeamOut;
  PROCESS_WIDE_STORAGE_STATIC(Settings) theSettings;
  PROCESS_WIDE_STORAGE_STATIC(DebugRequestTable) theDebugRequestTable;
  PROCESS_WIDE_STORAGE_STATIC(DebugDataTable) theDebugDataTable;
  PROCESS_WIDE_STORAGE_STATIC(StreamHandler) theStreamHandler;
  PROCESS_WIDE_STORAGE_STATIC(DrawingManager) theDrawingManager;
  PROCESS_WIDE_STORAGE_STATIC(DrawingManager3D) theDrawingManager3D;
  PROCESS_WIDE_STORAGE_STATIC(ReleaseOptions) theReleaseOptions;

public:
  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the outgoing debug message queue in this process.
  */
  static OutMessage& getDebugOut() {return *theDebugOut;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the outgoing team message queue in this process.
  */
  static OutMessage& getTeamOut() {return *theTeamOut;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the settings in this process.
  */
  static Settings& getSettings() {return *theSettings;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the debug request table in this process.
  */
  static DebugRequestTable& getDebugRequestTable() {return *theDebugRequestTable;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the debug data table in this process.
  */
  static DebugDataTable& getDebugDataTable() {return *theDebugDataTable;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the stream handler in this process.
  */
  static StreamHandler& getStreamHandler() {return *theStreamHandler;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the drawing manager in this process.
  */
  static DrawingManager& getDrawingManager() {return *theDrawingManager;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the 3-D drawing manager in this process.
  */
  static DrawingManager3D& getDrawingManager3D() {return *theDrawingManager3D;}

  /**
  * The method returns a reference to the process wide instance.
  * @return The instance of the release options in this process.
  */
  static ReleaseOptions& getReleaseOptions() {return *theReleaseOptions;}

  friend class Process; // The class Process can set these pointers.
  friend class Cognition; // The class Cognition can set theTeamOut.
  friend class ConsoleRoboCupCtrl; // The class ConsoleRoboCupCtrl can set theStreamHandler.
  friend class RobotConsole; // The class RobotConsole can set theDebugOut.
  friend class TeamComm3DCtrl;
  friend class Framework;
};
