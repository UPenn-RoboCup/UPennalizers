/**
* @file Platform/Win32Linux/File.cpp
* Declaration of class File for Win32 and Linux.
*/

#ifdef WIN32
#include <windows.h>
//#include <direct.h>
#else
#include <cstdlib> // for getenv
#include <sys/stat.h>
#include <unistd.h>
#endif

#include <cstring>
#include <cstdio>
#include <cstdarg>

#include "Platform/BHAssert.h"
#include "File.h"

File::File(const std::string& name, const char* mode, bool tryAlternatives) : stream(0)
{
  std::list<std::string> names = getFullNames(name);
  if(tryAlternatives)
    for(std::list<std::string>::const_iterator i = names.begin(); !stream && i != names.end(); ++i)
      stream = fopen(i->c_str(), mode);
  else
    stream = fopen(names.front().c_str(), mode);
}

std::list<std::string> File::getFullNames(const std::string& rawName)
{
#if (defined(LINUX) || defined(MACOSX)) && (defined(TARGET_SIM) || defined(TARGET_TOOL))
  std::string name(rawName);
  for(int i = name.length(); i >= 0; i--)
    if(name[i] == '\\')
      name[i] = '/';
#else
  const std::string& name(rawName);
#endif

  std::list<std::string> names;
  if(name[0] != '/' && name[0] != '\\' && name[0] != '.' && (name[0] == 0 || name[1] != ':')) // given path is relative to getBHDir()
    names.push_back(std::string(getBHDir()) + "/Config/" + name);
  else
    names.push_back(name);

  // if file doesn't exist; try falling back to the default location
  if(!strncmp(name.c_str(), "Locations/", 10) && strncmp(name.c_str() + 10, "Default/", 8))
  {
    const char* subPath = strchr(name.c_str() + 10, '/');
    if(subPath)
      names.push_back(std::string(getBHDir()) + "/Config/Locations/Default/" + (subPath + 1));
  }
  else if(!strncmp(name.c_str(), "Robots/", 7) && strncmp(name.c_str() + 7, "Default/", 8))
  {
    const char* subPath = strchr(name.c_str() + 7, '/');
    if(subPath)
      names.push_back(std::string(getBHDir()) + "/Config/Robots/Default/" + (subPath + 1));
  }
  return names;
}

File::~File()
{
  if(stream != 0)
    fclose((FILE*)stream);
}

void File::read(void* p, unsigned size)
{
  VERIFY(!eof());
  VERIFY(fread(p, 1, size, (FILE*)stream) > 0);
}

char* File::readLine(char* p, unsigned size)
{
  VERIFY(!eof());
  return fgets(p, size, (FILE*)stream);
}

void File::write(const void* p, unsigned size)
{
  //if opening failed, stream will be 0 and fwrite would crash
  ASSERT(stream != 0);
  VERIFY(fwrite(p, 1, size, (FILE*)stream) == size);
}

void File::printf(const char* format, ...)
{
  va_list args;
  va_start(args, format);
  vfprintf((FILE*)stream, format, args);
  va_end(args);
}

bool File::eof()
{
  //never use feof(stream), because it informs you only after reading
  //to far and is never reset, e.g. if the stream grows afterwards
  //our implementation can handle both correctly:
  if(! stream)
    return false;
  else
  {
    int c = fgetc((FILE*)stream);
    if(c == EOF)
      return true;
    else
    {
      VERIFY(ungetc(c, (FILE*)stream) != EOF);
      return false;
    }
  }
}

unsigned File::getSize()
{
  if(!stream)
    return 0;
  long currentPos = ftell((FILE*)stream);
  ASSERT(currentPos >= 0);
  VERIFY(fseek((FILE*)stream, 0, SEEK_END) == 0);
  long size =  ftell((FILE*)stream);
  VERIFY(fseek((FILE*)stream, currentPos, SEEK_SET) == 0);
  return (unsigned)size;
}

#ifdef WIN32
const char* File::getBHDir()
{
  static char dir[MAX_PATH] = {0};
  if(!dir[0])
  {
#if defined(TARGET_SIM) || defined(TARGET_TOOL)

    // determine module file from command line
    const char* commandLine = GetCommandLine();
    int len;
    if(*commandLine == '"')
    {
      commandLine++;
      const char* end = strchr(commandLine, '"');
      if(end)
        len = end - commandLine;
      else
        len = strlen(commandLine);
    }
    else
      len = strlen(commandLine);
    if(len >= sizeof(dir) - 8)
      len = sizeof(dir) - 8;
    memcpy(dir, commandLine, len);
    dir[len] = '\0';

    // if there is no given directory, use the current working dir
    if(!strchr(dir, '\\'))
    {
      len = int(GetCurrentDirectory(sizeof(dir) - 9, dir));
      if(len && dir[len - 1] != '\\')
      {
        dir[len++] = '\\';
        dir[len] = '\0';
      }
    }

    //drive letter in lower case:
    if(len && dir[1] == ':')
      *dir |= tolower(*dir);

    // try to find the config directory
    char* end = dir + len - 1;
    for(;;)
    {
      if(*end == '/' || *end == '\\' || *end == ':' || end == dir - 1)
      {
        if(*end == ':')
          *(end++) = '\\';
        strcpy(end + 1, "Config");
        DWORD attr = GetFileAttributes(dir);
        if(attr != INVALID_FILE_ATTRIBUTES && attr & FILE_ATTRIBUTE_DIRECTORY)
        {
          end[end > dir ? 0 : 1] = '\0';
          for(; end >= dir; end--)
            if(*end == '\\')
              *end = '/';
          return dir;
        }
      }
      if(end < dir)
        break;
      end--;
    }
    ASSERT(false);
#else
    strcpy(dir, ".");
#endif
  }
  return dir;
}
#endif

#if defined(LINUX) || defined(MACOSX)
const char* File::getBHDir()
{
  static char dir[FILENAME_MAX] = {0};
  if(!dir[0])
  {
    char* result = getenv("BH_DIR");
    if(result)
    {
      strcpy(dir, result);
    }
    else
    {
#if defined(TARGET_SIM) || defined(TARGET_TOOL)
      VERIFY(getcwd(dir, sizeof(dir) - 7) != 0);
      char* end = dir + strlen(dir) - 1;
      struct stat buff;;
      for(;;)
      {
        if(*end == '/' || end == dir - 1)
        {
          strcpy(end + 1, "Config");
          if(stat(dir, &buff) == 0)
            if(S_ISDIR(buff.st_mode))
            {
              end[end > dir ? 0 : 1] = '\0';
              return dir;
            }
        }
        if(end < dir)
          break;
        end--;
      }
#endif
      strcpy(dir, ".");///"media/userdata");
    }
  }
  return dir;
}
#endif

const char* File::getBHDir() {
  static char dir[FILENAME_MAX] = "/home/nao/bhwalk/";
  return dir;
}


bool File::isAbsolute(const char* path)
{
  return (path[0] && path[1] == ':') || path[0] == '/' || path[0] == '\\';
}

bool File::isExplicitRelative(const char* path)
{
  return path[0] == '.' && (path[1] == '/' || path[1] == '\\');
}
