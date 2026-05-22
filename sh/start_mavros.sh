#!/bin/bash

# ==== 1. 加载 ROS2 环境 ====
echo ">>> 正在加载 ROS 2 环境..."
source /opt/ros/noetic/setup.bash
echo ">>> 环境加载完成"

echo ">>> 启动 mavros 中..."
roslaunch mavros px4.launch fcu_url:="/dev/serial/by-id/usb-STMicroelectronics_STM32_Virtual_ComPort_20783986534B-if00:921600" gcs_url:="udp-b://@"

echo ">>> mavros 驱动已退出"
