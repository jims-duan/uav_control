#!/bin/bash

source /opt/ros/noetic/setup.bash
source /home/nano/ROS/lidar_racer/devel/setup.bash

# 重启服务
sudo systemctl restart uav_odom_converter.service
sleep 2

# 定义清理函数
cleanup() {
    echo ""
    echo "正在停止服务..."
    sudo systemctl stop uav_odom_converter.service
    
    # 终止所有roslaunch进程
    echo "正在终止roslaunch进程..."
    pkill -f "roslaunch"
    
    echo "已停止所有服务"
    exit 0
}

# 捕获 Ctrl+C (SIGINT) 和终止信号
trap cleanup SIGINT SIGTERM

# 启动第一个launch (后台运行)
echo "启动 swarm_exploration_realworld.launch..."
roslaunch exploration_manager swarm_exploration_realworld.launch &
PID1=$!

# 等待几秒确保第一个launch启动成功
sleep 3

# 启动第二个launch (后台运行)
echo "启动 test.launch..."
roslaunch swarm_ros_bridge test.launch &
PID2=$!

echo "两个launch文件已启动"
echo "按 Ctrl+C 停止所有"

# 等待两个进程
wait $PID1 $PID2

# 正常情况下退出后也停止服务
cleanup