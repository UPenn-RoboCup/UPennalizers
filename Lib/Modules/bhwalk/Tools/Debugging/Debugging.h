/**
 * Very simple debugging interface
 * 
 * @author Octavian Neamtu
 */

#pragma once

#include <iostream>

#define OUTPUT_ERROR(x) std::cerr << x << std::endl
#define OUTPUT_WARNING(x) std::cout << x << std::endl
#define OUTPUT(y, z, x) std::cout << x << std::endl
