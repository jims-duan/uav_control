#ifndef _UTILS_HPP
#define _UTILS_HPP

#include "ros/ros.h"

#include <cstdarg>
#include <cstdio>
#include <string>

inline const char* get_filename(const char* path) 
{
    const char* filename = strrchr(path, '/');
    return filename ? filename + 1 : path;
}
#define print_info(fmt, ...)   print_info_impl(get_filename(__FILE__), __LINE__, fmt, ##__VA_ARGS__)
#define print_warn(fmt, ...)   print_warn_impl(get_filename(__FILE__), __LINE__, fmt, ##__VA_ARGS__)
#define print_error(fmt, ...)  print_error_impl(get_filename(__FILE__), __LINE__, fmt, ##__VA_ARGS__)
#define print_debug(fmt, ...)  print_debug_impl(get_filename(__FILE__), __LINE__, fmt, ##__VA_ARGS__)

void print_info_impl( const char* file, int line, const char* fmt, ...);
void print_warn_impl( const char* file, int line, const char* fmt, ...);
void print_error_impl(const char* file, int line, const char* fmt, ...);
void print_debug_impl(const char* file, int line, const char* fmt, ...);



#endif
