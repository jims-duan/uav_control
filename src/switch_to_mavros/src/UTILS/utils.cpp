#include "utils.hpp"

/*--------------------------------UTILS---------------------------------*/
void print_info_impl(const char* file, int line, const char* fmt, ...)
{
    char buf[512];
    
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    // ROS1 版本
    ROS_INFO("[%s:%d] %s", file, line, buf);
}

void print_warn_impl(const char* file, int line, const char* fmt, ...)
{
    char buf[512];
    
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    // ROS1 版本
    ROS_WARN("[%s:%d] %s", file, line, buf);
}

void print_error_impl(const char* file, int line, const char* fmt, ...)
{
    char buf[512];
    
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    // ROS1 版本
    ROS_ERROR("[%s:%d] %s", file, line, buf);
}

void print_debug_impl(const char* file, int line, const char* fmt, ...)
{
    char buf[512];
    
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    // ROS1 版本
    ROS_DEBUG("[%s:%d] %s", file, line, buf);
}

void print_fatal_impl(const char* file, int line, const char* fmt, ...)
{
    char buf[512];
    
    va_list args;
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args);
    va_end(args);
    
    // ROS1 版本
    ROS_FATAL("[%s:%d] %s", file, line, buf);
}





