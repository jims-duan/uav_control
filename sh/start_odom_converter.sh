#!/bin/bash

# ==== 1. 加载 ROS2 环境 ====
echo ">>> 正在加载 ROS 2 环境..."
source /opt/ros/noetic/setup.bash
echo ">>> 环境加载完成"

echo ">>> 启动 odom_converter 中..."
source /home/nano/ROS/lidar_fuel/devel/setup.bash
roslaunch odom_converter odom_converter.launch

echo ">>> odom_converter 驱动已退出"
