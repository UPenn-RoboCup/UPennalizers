#ifndef TIMER_HH
#define TIMER_HH

#include <sys/time.h>
#include <iostream>

using namespace std;

namespace Upenn
{
  class Timer
  {

    public:
      Timer()
      {
        gettimeofday(&init,NULL);
      }

      ~Timer()
      {

      }
      
      static double GetAbsoluteTime()
      {
        static struct timeval temp;
        gettimeofday(&temp,NULL);
        return temp.tv_sec + temp.tv_usec*0.000001;
      }

      double GetInitTime()
      {
        return (init.tv_sec + (init.tv_usec*0.000001));
      }

      double Tic(bool verbose = false)
      {
        gettimeofday(&start,NULL);
        double dt = ((start.tv_sec+(start.tv_usec*0.000001)) - (init.tv_sec+(init.tv_usec*0.000001)));
        if (verbose)
          cout <<"*** Time elapsed since init: " << dt <<" seconds"<<endl;
        return dt;
      }

      double Toc(bool verbose = false)
      {
        gettimeofday(&stop,NULL);
        double dt = ((stop.tv_sec+(stop.tv_usec*0.000001)) - (start.tv_sec+(start.tv_usec*0.000001)));
        if (verbose)
          cout <<"*** Time elapsed: " << dt <<" seconds"<<endl;
        return dt;
      }

      double Toc(const char * message)
      {
        gettimeofday(&stop,NULL);
        double dt = ((stop.tv_sec+(stop.tv_usec*0.000001)) - (start.tv_sec+(start.tv_usec*0.000001)));
        cout <<"*** Time elapsed ("<<message<<"): " << dt <<" seconds"<<endl;
        return dt;
      }

    private:
      struct timeval init, start, stop;
  };
}
#endif //TIMER_HH

