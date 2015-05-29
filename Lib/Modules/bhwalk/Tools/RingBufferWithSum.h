/**
 * @file RingBufferWithSum.h
 *
 * Declaration of template class RingBufferWithSum
 *
 * @author Matthias Jüngel
 * @author Tobias Oberlies
 */

#pragma once


/**
 * @class RingBufferWithSum
 *
 * Template class for cyclic buffering of the last n values of the type C
 * and with a function that returns the sum of all entries.
 */
template <class C, int n> class RingBufferWithSum
{
public:
  /** Constructor */
  RingBufferWithSum() {init();}

  /**
   * initializes the RingBufferWithSum
   */
  inline void init() {current = n - 1; numberOfEntries = 0; sum = C();}

  /**
   * adds an entry to the buffer
   * \param value value to be added
   */
  inline void add(C value)
  {
    if(numberOfEntries == n) sum -= getEntry(numberOfEntries - 1);
    sum += value;
    current++;
    current %= n;
    if(++numberOfEntries >= n) numberOfEntries = n;
    buffer[current] = value;
  }

  /**
   * returns an entry
   * \param i index of entry counting from last added (last=0,...)
   * \return a reference to the buffer entry
   */
  inline C getEntry(int i) const
  {
    return buffer[(n + current - i) % n];
  }

  /**
   * returns the sum of all entries
   */
  inline C getSum() const
  {
    return sum;
  }

  /**
   * returns the smallest entry
   * \return the smallest entry
   */
  C getMinimum() const
  {
    // Return 0 if buffer is empty
    if(0 == numberOfEntries) return C();

    C min = buffer[0];
    for(int i = 0; i < numberOfEntries; i++)
    {
      if(buffer[i] < min) min = buffer[i];
    }
    return min;
  }

  /**
   * returns the average value of all entries
   * \return the average value
   */
  inline C getAverage()
  {
    // Return 0 if buffer is empty
    if(0 == numberOfEntries) return C();

    return (sum / (C)numberOfEntries);
  }

  /**
   * returns an entry
   * \param i index of entry counting from last added (last=0,...)
   * \return a reference to the buffer entry
   */
  inline C operator[](int i) const
  {
    return buffer[(n + current - i) % n];
  }

  /** Returns the number of elements that are currently in the ring buffer
  * \return The number
  */
  inline int getNumberOfEntries() const
  {
    return numberOfEntries;
  }

  /**
  * Returns the maximum entry count.
  * \return The maximum entry count.
  */
  inline int getMaxEntries() const
  {
    return n;
  }

private:
  int current;
  int numberOfEntries;
  C buffer[n];
  C sum;
};
