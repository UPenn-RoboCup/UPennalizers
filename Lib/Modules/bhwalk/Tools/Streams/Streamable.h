/*
* @file Tools/Streams/Streamable.h
*
* Base class for all types streamed through StreamHandler macros.
*
* @author Michael Spranger
* @author Tobias Oberlies
*/

#pragma once

#ifdef _MSC_VER
class type_info;
#elif defined(__clang__)
namespace std {class type_info;}
#else
#include <typeinfo>
#endif

#include <vector>
#include "InOut.h"

#ifdef RELEASE

/** Must be used at the end of any streaming operator or serialize(In*, Out*) function */
#define STREAM_REGISTER_FINISH()

// Macros dedicated for the use within the serialize(In*, Out*) of data types derived from Streamable function

/** Must be used at the beginning of the serialize(In*, Out*) function. */
#define STREAM_REGISTER_BEGIN()

/**
* Registers and streams a base class
* @param s A pointer to the base class.
*/
#define STREAM_BASE(s) _STREAM_BASE(s, )

/**
* Must be used at the beginning of the streaming operator
* @param s Object to be streamed within this streaming operator (should be the second argument to the streaming operator)
*/
#define STREAM_REGISTER_BEGIN_EXT(s)

/**
* Registers and streams a base class.
* @param s A reference to a base class representation.
*/
#define STREAM_BASE_EXT(stream, s) _STREAM_BASE_EXT(stream, s, )

#else

#define STREAM_REGISTER_FINISH() Streaming::finishRegistration();

#define STREAM_REGISTER_BEGIN() Streaming::startRegistration(typeid(*this), false);
#define STREAM_BASE(s) _STREAM_BASE(s, Streaming::registerBase();)

#define STREAM_REGISTER_BEGIN_EXT(s) Streaming::startRegistration(typeid(s), true);
#define STREAM_BASE_EXT(stream, s) _STREAM_BASE_EXT(stream, s, Streaming::registerBase();)

#endif

#define _STREAM_BASE(s, reg) \
  reg \
  this-> s ::serialize(in, out);

#define _STREAM_BASE_EXT(stream, s, reg) \
  reg \
  streamObject(stream, s);

/**
* Registration and streaming of a member.
* The first parameter is the attribute to be registered and streamed.
* If the type of that attribute is an enumeration and it is not defined
* in the current class, the name of the class in which it is defined 
* has to be specified as second parameter.
*/
#define STREAM(...) \
  STREAM_EXPAND(STREAM_EXPAND(STREAM_THIRD(__VA_ARGS__, STREAM_WITH_CLASS, STREAM_WITHOUT_CLASS))(__VA_ARGS__))

#define STREAM_THIRD(first, second, third, ...) third
#define STREAM_EXPAND(s) s // needed for Visual Studio

#define STREAM_WITHOUT_CLASS(s) \
  Streaming::streamIt(in, out, #s, s, Streaming::Casting<sizeof(Streaming::canBeConvertedToInt(Streaming::unwrap(s))) == sizeof(short)>::getNameFunction(*this, s));

#define STREAM_WITH_CLASS(s, class) \
  Streaming::streamIt(in, out, #s, s, Streaming::castFunction(s, class::getName));

/**
* Registration and streaming of a member in an external streaming operator
* (<< or >>).
* The second parameter is the attribute to be registered and streamed.
* If the type of that attribute is an enumeration, the name of the class 
* in which it is defined has to be specified as third parameter.
* @param stream Reference to the stream, that should be streamed to.
*/
#define STREAM_EXT(stream, ...) \
  STREAM_EXPAND(STREAM_EXPAND(STREAM_THIRD(__VA_ARGS__, STREAM_EXT_ENUM, STREAM_EXT_NORMAL))(stream, __VA_ARGS__))

#define STREAM_EXT_NORMAL(stream, s) Streaming::streamIt(stream, #s, s, Streaming::Casting<sizeof(Streaming::canBeConvertedToInt(Streaming::unwrap(s))) == sizeof(short)>::getNameFunction(stream, s));

#define STREAM_EXT_ENUM(stream, s, class) Streaming::streamIt(stream, #s, s, Streaming::castFunction(s, class::getName));

/**
* Streams a Vector2<float> as Vector2<short>.
* @param s The member to be streamed.
*/
#define STREAM_COMPRESSED_POSITION(s) \
  { \
    Vector2<short> _c(static_cast<short>(s.x), static_cast<short>(s.y)); \
    { \
      Vector2<short>& s(_c); \
      STREAM(s) \
    } \
    if(in) \
      s = Vector2<float>(static_cast<float>(_c.x), static_cast<float>(_c.y)); \
  }

/**
* Streams a float that is normalized to the interval [0:1] as a char.
*/
#define STREAM_COMPRESSED_NORMALIZED_FLOAT(s) \
  { \
    unsigned char _c = (unsigned char) (s * 255.0f); \
    { \
      unsigned char& s(_c); \
      STREAM(s) \
    } \
    if(in) \
      s = (float) _c / 255.0f; \
  }

/**
* Streams an angle discretized as a char.
*/
#define STREAM_COMPRESSED_ANGLE(s) \
  { \
    char _c = out ? Streaming::angleToChar(s) : 0; \
    { \
      char& s(_c); \
      STREAM(s) \
    } \
    if(in) \
      s = (float) _c * 3.1415926535897f / 128.0f; \
  }

/**
* Streams a member as an unsigned character. This is especially useful for
* small enums.
*/
#define STREAM_AS_UCHAR(s) \
  { \
    ASSERT(s >= 0 && s <= 255); \
    unsigned char _c(static_cast<unsigned char>(s)); \
    { \
      unsigned char& s(_c); \
      STREAM(s); \
    } \
    if(in) \
      Streaming::cast(s, _c); \
  }

/**
* Base class for all classes using the STREAM or STREAM_EXT macros (see Tools/Debugging/
* StreamHandler.h) for automatic streaming of class specifications to RobotControl.
* Only those instances of those classes can be parsed by RobotControl when they are
* transmitted through MODIFY and SEND macros (see Tools/Debugging/DebugDataTable.h).
*/
class ImplicitlyStreamable
{
};

/**
* Base class for all classes using the STREAM macros for streaming instances.
*/
class Streamable : public ImplicitlyStreamable
{
protected:
  virtual void serialize(In*, Out*) = 0;
public:
  void streamOut(Out&)const;
  void streamIn(In&);
};

In& operator>>(In& in, Streamable& streamable);

Out& operator<<(Out& out, const Streamable& streamable);

// Helpers

namespace Streaming
{
  Out& dummyStream();

  template<class T>
  static void registerDefaultElement(const std::vector<T>&)
  {
    static T dummy;
    dummyStream() << dummy;
  }

  template<class T>
  static void registerDefaultElement(const T*)
  {
    static T dummy;
    dummyStream() << dummy;
  }

  template<class T>
  In& streamComplexStaticArray(In& in, T inArray[], int size, const char* (*enumToString)(int))
  {
    int numberOfEntries = size / sizeof(T);
    for(int i = 0; i < numberOfEntries; ++i)
    {
      in.select(0, i, enumToString);
      in >> inArray[i];
      in.deselect();
    }
    return in;
  }

  template<class T>
  Out& streamComplexStaticArray(Out& out, T outArray[], int size, const char* (*enumToString)(int))
  {
    int numberOfEntries = size / sizeof(T);
    for(int i = 0; i < numberOfEntries; ++i)
    {
      out.select(0, i, enumToString);
      out << outArray[i];
      out.deselect();
    }
    return out;
  }

  template<class T>
  In& streamBasicStaticArray(In& in, T inArray[], int size, const char* (*enumToString)(int))
  {
    if(in.isBinary())
    {
      in.read(inArray, size);
      return in;
    }
    else
      return streamComplexStaticArray(in, inArray, size, enumToString);
  }

  template<class T>
  Out& streamBasicStaticArray(Out& out, T outArray[], int size, const char* (*enumToString)(int))
  {
    if(out.isBinary())
    {
      out.write(outArray, size);
      return out;
    }
    else
      return streamComplexStaticArray(out, outArray, size, enumToString);
  }

  inline In& streamStaticArray(In& in, unsigned char inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, unsigned char outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, char inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, char outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, unsigned short inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, unsigned short outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, short inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, short outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, unsigned int inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, unsigned int outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, int inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, int outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, float inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, float outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  inline In& streamStaticArray(In& in, double inArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(in, inArray, size, enumToString);}
  inline Out& streamStaticArray(Out& out, double outArray[], int size, const char* (*enumToString)(int)) {return streamBasicStaticArray(out, outArray, size, enumToString);}
  template<class T>
  In& streamStaticArray(In& in, T inArray[], int size, const char* (*enumToString)(int)) {return streamComplexStaticArray(in, inArray, size, enumToString);}
  template<class T>
  Out& streamStaticArray(Out& out, T outArray[], int size, const char* (*enumToString)(int)) {return streamComplexStaticArray(out, outArray, size, enumToString);}

  template<class T, class U> void cast(T& t, const U& u) {t = static_cast<T>(u);}

  void finishRegistration();

  void startRegistration(const std::type_info& ti, bool registerWithExternalOperator);

  void registerBase();

  void registerWithSpecification(const char* name, const std::type_info& ti);

  void registerEnum(const std::type_info& ti, const char* (*fp)(int));

  std::string demangle(const char* name);

  char angleToChar(float angle);

  const char* skipDot(const char* name);

  template<typename S> struct Streamer
  {
    static void stream(In* in, Out* out, const char* name, S& s, const char* (*enumToString)(int))
    {
#ifndef RELEASE
      registerWithSpecification(name, typeid(s));
      if(enumToString)
        Streaming::registerEnum(typeid(s), (const char* (*)(int)) enumToString);
#endif
      if(in)
      {
        in->select(name, -2, enumToString);
        *in >> s;
        in->deselect();
      }
      else
      {
        out->select(name, -2, enumToString);
        *out << s;
        out->deselect();
      }
    }
  };

  template<typename E, size_t N> struct Streamer<E[N]>
  {
    typedef E S[N];
    static void stream(In* in, Out* out, const char* name, S& s, const char* (*enumToString)(int))
    {
#ifndef RELEASE
      registerWithSpecification(name, typeid(s));
      if(enumToString)
        Streaming::registerEnum(typeid(s[0]), (const char* (*)(int)) enumToString);
#endif
      if(in)
      {
        in->select(name, -1);
        streamStaticArray(*in, s, sizeof(s), enumToString);
        in->deselect();
      }
      else
      {
        out->select(name, -1);
        streamStaticArray(*out, s, sizeof(s), enumToString);
        out->deselect();
      }
    }
  };

  template<typename E> struct Streamer<std::vector<E> >
  {
    typedef std::vector<E> S;
    static void stream(In* in, Out* out, const char* name, S& s, const char* (*enumToString)(int))
    {
#ifndef RELEASE
      registerDefaultElement(s);
      registerWithSpecification(name, typeid(&s[0]));
      if(enumToString)
        Streaming::registerEnum(typeid(s[0]), (const char* (*)(int)) enumToString);
#endif
      if(in)
      {
        in->select(name, -1);
        unsigned _size;
        *in >> _size;
        s.resize(_size);
        if(!s.empty())
          streamStaticArray(*in, &s[0], s.size() * sizeof(s[0]), enumToString);
        in->deselect();
      }
      else
      {
        out->select(name, -1);
        *out << (unsigned) s.size();
        if(!s.empty())
          streamStaticArray(*out, &s[0], s.size() * sizeof(s[0]), enumToString);
        out->deselect();
      }
    }
  };
  
  template<typename S> void streamIt(In* in, Out* out, const char* name, S& s, const char* (*enumToString)(int) = 0)
    {Streamer<S>::stream(in, out, name, s, enumToString);}
  template<typename S> void streamIt(In& in, const char* name, S& s, const char* (*enumToString)(int) = 0)
    {Streamer<S>::stream(&in, 0, skipDot(name), s, enumToString);}
  template<typename S> void streamIt(Out& out, const char* name, const S& s, const char* (*enumToString)(int) = 0)
    {Streamer<S>::stream(0, &out, skipDot(name), const_cast<S&>(s), enumToString);}

  template<typename T> struct Function
  {
    inline static const char* (*cast(const char* (*enumToString)(T)))(int)
    {
      return (const char* (*)(int)) enumToString;
    }
  };
  
  template<typename T> inline const char* (*castFunction(const T&, const char* (*enumToString)(T)))(int)
  {
    return (const char* (*)(int)) enumToString;
  }
  
  template<typename T, size_t N> inline const char* (*castFunction(const T(&)[N], const char* (*enumToString)(T)))(int)
  {
    return (const char* (*)(int)) enumToString;
  }
  
  template<typename T> inline const char* (*castFunction(const std::vector<T>&, const char* (*enumToString)(T)))(int)
  {
    return (const char* (*)(int)) enumToString;
  }
  
  template<bool isEnum = true> struct Casting
  {
    template<typename T, typename E> inline static const char* (*getNameFunction(const T&, const E&))(int)
    {
      return Function<E>::cast(T::getName);
    }
    
    template<typename T, typename E, size_t N> inline static const char* (*getNameFunction(const T&, const E(&)[N]))(int)
    {
      return Function<E>::cast(T::getName);
    }
    
    template<typename T, typename E> inline static const char* (*getNameFunction(const T&, const std::vector<E>&))(int)
    {
      return Function<E>::cast(T::getName);
    }
	
    template<typename T> inline static const char* (*getNameFunction(const T&, const int&))(int)
    {
      return 0;
    }
    
    template<typename T, size_t N> inline static const char* (*getNameFunction(const T&, const int(&)[N]))(int)
    {
      return 0;
    }
    
    template<typename T> inline static const char* (*getNameFunction(const T&, const std::vector<int>&))(int)
    {
      return 0;
    }
  };
  
  template<> struct Casting<false>
  {
    template<typename T, typename E> inline static const char* (*getNameFunction(const T&, const E&))(int)
    {
      return 0;
    }
  };

  short canBeConvertedToInt(int);
  char canBeConvertedToInt(char);
  char canBeConvertedToInt(unsigned char);
  char canBeConvertedToInt(short);
  char canBeConvertedToInt(unsigned short);
  char canBeConvertedToInt(unsigned int);
  char canBeConvertedToInt(long);
  char canBeConvertedToInt(unsigned long);
  char canBeConvertedToInt(long long);
  char canBeConvertedToInt(unsigned long long);
  char canBeConvertedToInt(float);
  char canBeConvertedToInt(double);
  char canBeConvertedToInt(bool);
  char canBeConvertedToInt(...);
  
  template<typename T> const T unwrap(const T&);
  template<typename T, size_t N> const T unwrap(const T(&)[N]);;
  template<typename T> const T unwrap(const std::vector<T>&);;
}

