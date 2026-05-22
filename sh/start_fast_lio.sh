#!/bin/bash

# ==== 0. 检查并关闭已有 fast_lio mapping 节点 ====
EXIST_PIDS=$(pgrep -f "fastlio_mapping")
if [ ! -z "$EXIST_PIDS" ]; then
    echo ">>> 检测到已有 Fast-LIO 进程，先关闭它们: $EXIST_PIDS"
    # 正常退出
    pkill -f "fastlio_mapping"
    sleep 1
    # 再检查一次，如果还有残留进程
    REMAINING_PIDS=$(pgrep -f "fastlio_mapping")
    if [ ! -z "$REMAINING_PIDS" ]; then
        echo "!!! 残留 Fast-LIO 进程未关闭，强制杀掉: $REMAINING_PIDS"
        pkill -9 -f "fastlio_mapping"
    fi
    echo ">>> 已关闭旧的 Fast-LIO 驱动"
fi

# ==== 1. 加载 ROS 1 环境 ====
echo ">>> 正在加载 ROS 1 环境..."
source /opt/ros/noetic/setup.bash
source /home/nano/ROS/lidar_livox/devel/setup.bash
echo ">>> ROS 1 环境加载完成"

# ==== 2. 启动 Fast-LIO mapping 节点 ====
echo ">>> 启动 Fast-LIO 驱动..."
roslaunch fast_lio mapping_mid360.launch

echo ">>> Fast-LIO 驱动已退出"
