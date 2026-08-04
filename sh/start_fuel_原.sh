#!/bin/bash

source /opt/ros/noetic/setup.bash
source /home/nano/ROS/lidar_fuel/devel/setup.bash

# 重启服务
sudo systemctl restart uav_odom_converter.service
sleep 2

# 定义清理函数
cleanup() {
    echo ""
    echo "正在停止服务..."
    sudo systemctl stop uav_odom_converter.service
    echo "已停止服务"
    exit 0
}

# 捕获 Ctrl+C (SIGINT) 和终止信号
trap cleanup SIGINT SIGTERM

# 运行 roslaunch
roslaunch exploration_manager exploration.launch

# 正常情况下 roslaunch 退出后也停止服务
cleanup