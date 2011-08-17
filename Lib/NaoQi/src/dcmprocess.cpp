#include "dcmprocess.h"
#include "luafifo.h"

#include "sensor_process.h"
#include "actuator_process.h"

#include <alproxies/dcmproxy.h>

#include <alcommon/alproxy.h>

#include <stdlib.h>

using namespace AL;

const char luaInitFilename[] = "/usr/local/lib/lua/5.1/nao_init.lua";

DCMProxy* dcm = 0;

void preProcess() {
  actuator_process();
}

void postProcess() {
  sensor_process();

  // Lua interpreter
  luafifo_doread();
  luafifo_pcall("postProcess");
}

void close() {
  //std::cout << "DcmProcess: closing..." << std::endl;

  // Unregister callbacks
  dcm->getGenericProxy()->getModule()->atPreProcess(NULL);
  dcm->getGenericProxy()->getModule()->atPostProcess(NULL);

  luafifo_close();

  if (dcm)
    delete dcm;

  std::cout << "DcmProcess: done." << std::endl;
}

int create(ALPtr<ALBroker> pBroker) {
  std::cout << "DcmProcess: starting..." << std::endl;

  if (sensor_process_init(pBroker)) {
    std::cerr << "Problem with sensor_process_init" << std::endl;
  }
  if (actuator_process_init(pBroker)) {
    std::cerr << "Problem with actuator_process_init" << std::endl;
  }

  // Open global symbols in liblua.so
  luafifo_dlopen_hack();
  if (luafifo_open() != 0) {
    std::cerr << "Could not start Lua interpreter" << std::endl;
    return -1;
  }

  luafifo_dofile(luaInitFilename);

  try {
    // DCM Proxy
    dcm = new DCMProxy(pBroker);

    // Register callbacks
    dcm->getGenericProxy()->getModule()->atPreProcess(&preProcess);
    dcm->getGenericProxy()->getModule()->atPostProcess(&postProcess);
  } catch(AL::ALError& e) {
    std::cerr << "DcmProcess error: " << e.toString() << std::endl;
    close();
    return 0;
  }

  std::cout << "DcmProcess: started." << std::endl;
  return 0;
}


class DcmProcess : public ALModule {
public:
  DcmProcess(ALPtr<ALBroker> pBroker, const std::string& pName): ALModule(pBroker, pName) {
    setModuleDescription( "A module to access DCM." );

    if (create(pBroker) != 0)
      throw ALERROR(pName, "constructor", "");
  }

  virtual ~DcmProcess() {
    close();
  }

  void dataChanged(const std::string& pDataName, const ALValue& pValue, const std::string& pMessage) {}
  bool innerTest() { return true; }
};

extern "C" int _createModule( ALPtr<ALBroker> pBroker ) {      
  ALModule::createModule<DcmProcess>(pBroker, "DcmLua");
  return 0;
}

extern "C" int _closeModule() {
  return 0;
}
