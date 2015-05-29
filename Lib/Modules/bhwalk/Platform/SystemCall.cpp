/**
* @file  Platform/linux/SystemCall.cpp
* @brief static class for system calls, Linux implementation
* @attention this is the Linux implementation
*
* @author <A href=mailto:brunn@sim.informatik.tu-darmstadt.de>Ronnie Brunn</A>
* @author <A href=mailto:martin@martin-loetzsch.de>Martin Lötzsch</A>
* @author <A href=mailto:risler@sim.informatik.tu-darmstadt.de>Max Risler</A>
* @author <a href=mailto:dueffert@informatik.hu-berlin.de>Uwe Dffert</a>
*/

#include "SystemCall.h"

#include "BHAssert.h"
#ifdef __APPLE__
#else
#include <sys/sysinfo.h>
#endif

#include <time.h>
#include <unistd.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <cstring>
#include <pthread.h>
#include <ctime>

unsigned SystemCall::getCurrentSystemTime()
{
  return getRealSystemTime();
}

unsigned SystemCall::getRealSystemTime()
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  unsigned int time = (unsigned int)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000l);
  static unsigned base = 0;
  if(!base)
    base = time - 10000; // avoid time == 0, because it is often used as a marker
  return time - base;
}

unsigned long long SystemCall::getCurrentThreadTime()
{
  clockid_t cid;
  struct timespec ts;

  VERIFY(pthread_getcpuclockid(pthread_self(), &cid) == 0);
  VERIFY(clock_gettime(cid, &ts) == 0);

  unsigned long long time = ts.tv_sec * 1000000 + ts.tv_nsec / 1000;

  static unsigned long long base = 0;
  if(!base)
    base = time - 10000 * 1000;
  return time - base;
}

const char* SystemCall::getHostName()
{
  static const char* hostname = 0;
  if(!hostname)
  {
    static char buf[100] = {0};
    VERIFY(!gethostname(buf, sizeof(buf)));
    hostname = buf;
  }
  return hostname;
}

const char* SystemCall::getHostAddr()
{
  static const char* hostaddr = 0;
#ifdef STATIC // Prevent warnings during static linking
  ASSERT(false); // should not be called
#else
  if(!hostaddr)
  {
    static char buf[100];
    hostent* hostAddr = (hostent*) gethostbyname(getHostName());
    if(hostAddr && *hostAddr->h_addr_list)
      strcpy(buf, inet_ntoa(*(in_addr*) *hostAddr->h_addr_list));
    else
      strcpy(buf, "127.0.0.1");
    hostaddr = buf;
  }
#endif
  return hostaddr;
}

SystemCall::Mode SystemCall::getMode()
{
  return physicalRobot;
}

void SystemCall::sleep(unsigned ms)
{
  usleep(1000 * ms);
}

void SystemCall::getLoad(float& mem, float load[3])
{
  struct sysinfo info;
  if(sysinfo(&info) == -1)
    load[0] = load[1] = load[2] = mem = -1.f;
  else
  {
    load[0] = float(info.loads[0]) / 65536.f;
    load[1] = float(info.loads[1]) / 65536.f;
    load[2] = float(info.loads[2]) / 65536.f;
    mem = float(info.totalram - info.freeram) / float(info.totalram);
  }
}


#ifdef STATIC // Prevent warnings during static linking

#include <cstdlib>
#include <cerrno>
#include <sys/stat.h>

extern "C" char* mktemp(char* t)
{
  int l = strlen(t);
  if(l < 6)
  {
    errno = EINVAL;
    return 0;
  }

  for(int i = l - 6; i < l; ++i)
    if(t[i] != 'X')
    {
      errno = EINVAL;
      return 0;
    }

  for(int r = rand(); ; ++r)
  {
    int n = r;
    for(int i = l - 1; i >= l - 6; --i)
    {
      t[i] = '0' + n % 10;
      n /= 10;
    }

    struct stat stbuf;
    if(stat(t, &stbuf) != 0)
      return t;
  }
}

#endif
