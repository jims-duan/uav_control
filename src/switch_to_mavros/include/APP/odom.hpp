#ifndef _ODOM_HPP
#define _ODOM_HPP

#include "main.hpp"
#include <nav_msgs/Odometry.h>
#include <nav_msgs/Odometry.h>
#include <mavros_msgs/PositionTarget.h>
#include <quadrotor_msgs/PositionCommand.h>

extern ros::Publisher odom_pub;
extern ros::Publisher pos_target_pub;

typedef void (*odom_callback_p)(const nav_msgs::Odometry::ConstPtr& msg);
typedef void (*pos_cmd_callback_p)(const quadrotor_msgs::PositionCommand::ConstPtr& msg);
typedef struct
{
    odom_callback_p odom_callback;
    pos_cmd_callback_p pos_cmd_callback;
    void (*timer_5ms)(void);
    double yaw_rad;
    double yaw_deg;
} odom_structure;
extern odom_structure odom_struct;

typedef struct
{
    double x;
    double y;
    double z;
    double vx;
    double vy;
    double vz;
    double yaw;
} PoseVel_Structure;
extern PoseVel_Structure PoseVel;


#endif
