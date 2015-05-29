/*
* @file Tools/Enum.h
* Defines a macro that declares an enum and provides
* a function to access the names of its elements.
*
* @author Thomas Röfer
*/

#pragma once

#include <string>
#include <vector>

/**
* @class EnumName
* The class converts a single comma-separated string of enum names
* into single entries that can be accessed in constant time.
* It is the worker class for the templated version below.
*/
class EnumName
{
private:
  std::vector<std::string> names; /**< The vector of enum names. */
  
  /**
  * A method that trims a string, i.e. removes spaces from its
  * beginning and end.
  * @param s The string that is trimmed.
  * @return The string without spaces at the beginning and at its end.
  */
  static std::string trim(const std::string& s);
  
public:
  /**
  * Constructor.
  * @param enums A string that contains a comma-separated list of enum
  *              elements. It is allowed that an element is initialized
  *              with the value of its predecessor. Any other 
  *              initializations are forbidden.
  *              "a, b, numOfLettersBeforeC, c = numOfLettersBeforeC, d" 
  *              would be a legal parameter.
  * @param numOfEnums The number of enums in the string. Reassignments do
  *                   not count, i.e. in the example above, this 
  *                   parameter had to be 4.
  */
  EnumName(const std::string& enums, size_t numOfEnums);

  /**
  * The method returns the name of an enum element.
  * @param index The index of the enum element.
  * @return Its name.
  */
  const char* getName(size_t e) {return e >= names.size() ? 0 : names[e].c_str();}
};

/**
* Defining an enum and a function get<Enum>Name(<Enum>) that can return
* the name of each enum element. The enum will automatically
* contain an element numOf<Enum>s that reflects the number of
* elements defined.
*/
#define ENUM(Enum, ...) \
  enum Enum {__VA_ARGS__, numOf##Enum##s}; \
  inline static const char* getName(Enum e) {static EnumName en(#__VA_ARGS__, (size_t) numOf##Enum##s); return en.getName((size_t) e);}
