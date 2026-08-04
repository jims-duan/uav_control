#!/bin/bash

# ==== 1. 加载 ROS 环境 ====
echo ">>> 正在加载 ROS 环境..."
source /opt/ros/noetic/setup.bash
echo ">>> 环境加载完成"

# 清理函数：停止所有服务
cleanup() {
    echo ""
    echo ">>> 正在停止所有服务..."
    sudo systemctl stop uav_switch_to_mavros.service
    sudo systemctl stop uav_rc_control.service
    echo ">>> 所有服务已停止"
    exit 0
}

# 捕获退出信号
trap cleanup SIGINT SIGTERM

# 先启动 mavros
echo ">>> 启动 mavros 中..."
roslaunch mavros px4.launch fcu_url:="/dev/serial/by-id/usb-STMicroelectronics_STM32_Virtual_ComPort_20783986534B-if00:921600" gcs_url:="udp-b://@" &

# 等待 MAVROS 完全启动
echo ">>> 等待 MAVROS 初始化 (5秒)..."
sleep 3

# 检查 MAVROS 是否运行
if pgrep -f "roslaunch.*mavros" > /dev/null; then
    echo ">>> MAVROS 已启动"
else
    echo ">>> 警告: MAVROS 可能未正常启动"
fi

# 启动依赖服务
echo ">>> 启动依赖服务..."
sudo systemctl restart uav_switch_to_mavros.service
sleep 1
sudo systemctl restart uav_rc_control.service
sleep 1

echo ">>> 所有服务已启动，按 Ctrl+C 退出"

# 等待 MAVROS 进程结束
wait