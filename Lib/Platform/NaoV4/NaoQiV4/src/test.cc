#include <vector>
#include <map>
#include <string>
#include <stdlib.h>

//#include "sensor_process.h"


typedef struct {
  std::vector<double *> ptrs;
  int command;
} structCommand;

std::vector<structCommand> commands;

main() {
  double a;

  commands.clear();

  structCommand cmd;
  cmd.ptrs.push_back(&a);
  cmd.ptrs.push_back(&a+1);
  cmd.command = 1;

  commands.push_back(cmd);
  commands.push_back(cmd);
  for (int i = 0; i < commands.size(); i++) {
    printf("%p %d\n",commands[i].ptrs[0], commands[i].command);
  }
  return 0;
}
