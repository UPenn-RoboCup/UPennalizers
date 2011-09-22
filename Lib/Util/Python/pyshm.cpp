// TODO: change list arguments/returns to numpy nparrays

// boost python interface headers
#include <boost/python/module.hpp>
#include <boost/python/def.hpp>
#include <boost/python/numeric.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/extract.hpp>

// boost shared memory headers
#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/allocators/allocator.hpp>

#include <vector>
#include <string>

using namespace boost::python;
using namespace boost::interprocess;

typedef double value_t;
static std::vector<managed_shared_memory *> shmHandles;
static std::vector<std::string> shmNames;

BOOST_PYTHON_FUNCTION_OVERLOADS(create_overloads, create, 1, 2);
BOOST_PYTHON_FUNCTION_OVERLOADS(next_overloads, next, 1, 2);

int create(const char* name, int size = 65536) {
  int nshm = shmHandles.size();
  shmHandles.push_back(new managed_shared_memory(open_or_create, name, size));
  shmNames.push_back(std::string(name));

  return nshm;
}

int shmopen(const char* name) {
  int nshm = shmHandles.size();
  shmHandles.push_back(new managed_shared_memory(open_only, name));
  shmNames.push_back(std::string(name));

  return nshm;
}

void destroy(int nshm) {
  if (nshm < shmHandles.size() && shmHandles[nshm]) {
    shared_memory_object::remove(shmNames[nshm].c_str());
    delete shmHandles[nshm];
    // set pointer to null so we know its destroyed
    shmHandles[nshm] = NULL;
  }
}

void set(int nshm, const char* key, list values) {
  int nvalue = len(values);

  if (nshm > shmHandles.size() or !shmHandles[nshm]) {
    printf("WARNING: No Shared Memory Handle exists for id: %d\n", nshm);
    return;
  }

  // find key in shm
  std::pair<value_t*, std::size_t> ret;
  ret = shmHandles[nshm]->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;

  if (pr == NULL) {
    // construct the shm key if it doesn't exist
    pr = shmHandles[nshm]->construct<value_t>(key)[nvalue]();    
  } else if (n != nvalue) {
    // if it exists but is not the correct size
    // create a new key with the correct size
    printf("WARNING: Input size %d != current block size %d. Resizing %s block.\n", nvalue, n, key);
    shmHandles[nshm]->destroy_ptr(pr);
    pr = shmHandles[nshm]->construct<value_t>(key)[nvalue]();    
  }

  for (int i = 0; i < nvalue; i++) {
      pr[i] = extract<value_t>(values[i]);
  }
}

list get(int nshm, const char* key){
  list ret_list;
  if (nshm < shmHandles.size() && shmHandles[nshm]) {
    // try to find key
    std::pair<value_t*, std::size_t> ret;
    ret = shmHandles[nshm]->find<value_t>(key);
    value_t *pr = ret.first;
    int n = ret.second;

    if (pr == NULL) {
      return ret_list;
    }
    for (int i = 0; i < n; i++) {
      ret_list.append(pr[i]);
    }

    return ret_list;
  } else {
    // handle does not correspond to a 
    printf("WARNING: No Shared Memory Handle exists for id: %d\n", nshm);
    return ret_list;
  }
}


int size(int nshm, const char* key) {
  std::pair<value_t*, std::size_t> ret;
  ret = shmHandles[nshm]->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;

  if (pr == NULL) {
    return 0;
  } else {
    return n;
  }
}


const char* next(int nshm, const char* key = NULL) {
  if (nshm < shmHandles.size() && shmHandles[nshm]) {
    managed_shared_memory *shm = shmHandles[nshm];

    typedef managed_shared_memory::const_named_iterator const_named_it;
    const_named_it named_beg = shm->named_begin();
    const_named_it named_end = shm->named_end();

    if (key == NULL) {
      // first time next is called
      if (named_beg != named_end) { 
        return named_beg->name();
      } else {
        // there are no keys
        return "";
      }
    }

    bool find = false;
    do {
      if (find) {
        return named_beg->name();
      } else {
        const managed_shared_memory::char_type *name = named_beg->name();
        std::size_t name_len = named_beg->name_length();
        if (std::string(key) == std::string(name)) {
          find = true;
        }
      }
    } while (++named_beg != named_end);

    // no more keys
    return "";
  } else {
    printf("WARNING: No Shared Memory Handle exists for id: %d\n", nshm);
    return NULL;
  }
}


char const* greet() {
 return("hello, world");
}

BOOST_PYTHON_MODULE(pyshm) {
  using namespace boost::python;
  // set numeric type to numpy
  numeric::array::set_module_and_type("numpy", "ndarray");


  def("greet", greet);
  def("create", create, create_overloads());
  def("open", shmopen);
  def("destroy", destroy);
  def("get", get);
  def("set", set);
  def("next", next, next_overloads());
}

