#include <ros/ros.h>
#include <thread>
#include <iostream>
#include <atomic>
#include <chrono>
#include <nav_msgs/Odometry.h>
#include "odom.hpp"
#include <geometry_msgs/Quaternion.h>
#include <nav_msgs/Odometry.h>
#include <mavros_msgs/PositionTarget.h>
#include <quadrotor_msgs/PositionCommand.h>


// 5ms定时器回调函数（如需处理，可自定义内容）
void timer5ms_Callback(const ros::TimerEvent&)
{
    ROS_INFO("5ms timer callback triggered");
}

int main(int argc, char** argv)
{
    // 设置中文编码（针对终端输出）
    setlocale(LC_ALL, "zh_CN.UTF-8");

    // 初始化ROS节点
    ros::init(argc, argv, "switch_to_mavros_node");
    ros::NodeHandle nh;

    // 使用私有命名空间读取参数
    ros::NodeHandle private_nh("~");

    std::string output_topic = "/mavros/odometry/out";
    // PositionTarget 控制指令
    pos_target_pub = nh.advertise<mavros_msgs::PositionTarget>("/mavros/setpoint_raw/local", 10);
    odom_pub = nh.advertise<nav_msgs::Odometry>(output_topic, 10);
    // 创建Odometry订阅器
    ros::Subscriber odom_sub = nh.subscribe<nav_msgs::Odometry>("/Odom_high_freq", 100, odom_struct.odom_callback);
    ros::Subscriber pos_cmd_sub = nh.subscribe<quadrotor_msgs::PositionCommand>("/planning/pos_cmd", 10, odom_struct.pos_cmd_callback);

    // 创建5ms定时器
    ros::Timer timer_5ms = nh.createTimer(ros::Duration(0.5), timer5ms_Callback);

    ros::spin();

    return 0;
}