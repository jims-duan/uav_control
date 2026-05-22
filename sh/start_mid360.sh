#!/bin/bash

# ==== 0. 关闭已有 Livox 驱动（如果存在） ====
EXIST_PIDS=$(pgrep -f "roslaunch livox_ros_driver livox_mid360.launch")
if [ ! -z "$EXIST_PIDS" ]; then
    echo ">>> 检测到已有 Livox 驱动进程，先关闭它: $EXIST_PIDS"
    pkill -f livox_ros_driver
    sleep 1
    # 再检查一次，如果还有残留进程
    if pgrep -f livox_ros_driver > /dev/null; then
        echo "!!! 残留进程未关闭，强制杀掉..."
        pkill -9 -f livox_ros_driver
    fi
    echo ">>> 已关闭旧的 Livox 驱动"
fi

# ==== 1. 加载 ROS1 环境 ====
echo ">>> 正在加载 ROS 1 环境..."
source /opt/ros/noetic/setup.bash
source /home/nano/ROS/lidar_livox/devel/setup.bash
echo ">>> 环境加载完成"

# ==== 2. 从配置文件获取 host_ip ====
HOST_IP=$(grep -Po '"cmd_data_ip"\s*:\s*"\K[0-9.]+' /home/nano/ROS/lidar_livox/src/livox_ros_driver2/config/MID360_config.json)
echo ">>> 配置文件 host_ip: $HOST_IP"

# ==== 2b. 循环检测电脑 IP ====
while true; do
    ETH_IP=$(ip -4 addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    echo ">>> 当前电脑 eth0 IP: $ETH_IP"

    if [ "$HOST_IP" == "$ETH_IP" ]; then
        echo ">>> 电脑 IP 与配置文件 host_ip 一致"
        break
    else
        echo "!!! 电脑 IP 与配置文件 host_ip 不一致，请修改 IP 或 JSON 配置"
        echo ">>> 5 秒后重试..."
        sleep 5
    fi
done

# ==== 3. Ping 雷达 ====
LIDAR_IP=$(grep -Po '"ip"\s*:\s*"\K[0-9.]+' /home/nano/ROS/lidar_livox/src/livox_ros_driver2/config/MID360_config.json)
echo ">>> 正在 ping 雷达 ($LIDAR_IP) ..."

while true; do
    ping -c 3 $LIDAR_IP > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ">>> 雷达连接正常"
        break
    else
        echo "!!! 无法 ping 通雷达 ($LIDAR_IP)，请检查网线和雷达电源"
        echo ">>> 5 秒后重试..."
        sleep 1
    fi
done

# ==== 4. 启动 Livox 驱动 ====
echo ">>> 启动 Livox 驱动中..."
roslaunch livox_ros_driver2 msg_MID360.launch

echo ">>> Livox 驱动已退出"
