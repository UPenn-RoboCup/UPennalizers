/*
* @file Tools/Enum.h
* Implements a class converts a single comma-separated string 
* of enum names into single entries that can be accessed in 
* constant time.
* @author Thomas Röfer
*/

#include "Enum.h"
#include "Platform/BHAssert.h"

std::string EnumName::trim(const std::string& s)
{
  std::string::size_type pos = s.find_first_not_of(' ');
  if(pos != std::string::npos)
    return s.substr(pos, s.find_last_not_of(' ') + 1);
  else 
    return s;
}

EnumName::EnumName(const std::string& enums, size_t numOfEnums) : names(numOfEnums) 
{
  std::string::size_type pBegin = 0;
  std::string::size_type pEnd = enums.find(',');
  size_t index = 0;
  for(;;)
  {
    std::string name = trim(pEnd == std::string::npos ? enums.substr(pBegin) :enums.substr(pBegin, pEnd - pBegin));
    std::string::size_type p = name.find('=');
    if(p != std::string::npos)
    {
      ASSERT(trim(name.substr(p + 1)) == names[index - 1]);
      name = trim(name.substr(0, p));
      --index;
    }
    names[index++] = name;
    if(pEnd == std::string::npos)
      break;
    pBegin = pEnd + 1;
    pEnd = enums.find(',', pBegin);
  }
  ASSERT(index == numOfEnums);
}
