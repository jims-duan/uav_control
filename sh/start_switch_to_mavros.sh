#!/bin/bash

# ==== 1. 加载 ROS2 环境 ====
echo ">>> 正在加载 ROS 2 环境..."
source /opt/ros/noetic/setup.bash
echo ">>> 环境加载完成"

echo ">>> 启动 switch_to_mavros 中..."
source /home/nano/ROS/uav_control/devel/setup.bash
roslaunch switch_to_mavros switch_to_mavros.launch

echo ">>> switch_to_mavros 驱动已退出"
