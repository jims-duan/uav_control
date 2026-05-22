#!/bin/bash

# ==== 配置参数 ====
RESTART_DELAY=3      # 重启延迟时间（秒）
FOXGLOVE_PORT=${FOXGLOVE_PORT:-8765}  # foxglove端口

# ==== 全局变量 ====
RESTART_COUNT=0
SHOULD_EXIT=false

# ==== 清理函数 ====
cleanup() {
    echo ">>> 收到退出信号，清理进程并退出..."
    SHOULD_EXIT=true
    killall -9 foxglove_bridge 2>/dev/null
    killall -9 roscore 2>/dev/null
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# ==== 启动函数 ====
start_foxglove() {
    local attempt=$1
    
    echo ""
    echo "========================================="
    echo ">>> 第 $attempt 次启动 foxglove bridge"
    echo "========================================="
    
    # ==== 1. 加载 ROS 环境 ====
    echo ">>> 正在加载 ROS 环境..."
    source /opt/ros/noetic/setup.bash
    echo ">>> 环境加载完成"
    
    # ==== 2. 设置必要的环境变量 ====
    export ROS_MASTER_URI=http://localhost:11311
    export ROS_IP=$(hostname -I | awk '{print $1}')
    
    # 备用方法获取IP
    if [ -z "$ROS_IP" ] || [ "$ROS_IP" = "127.0.0.1" ]; then
        export ROS_IP=$(ip addr show | grep -E 'inet (192\.168|10\.|172\.)' | head -1 | awk '{print $2}' | cut -d/ -f1)
    fi
    
    echo ">>> ROS_MASTER_URI: $ROS_MASTER_URI"
    echo ">>> ROS_IP: $ROS_IP"
    
    # ==== 3. 检查并确保 ROS master 运行 ====
    echo ">>> 检查 ROS master..."
    if ! rostopic list > /dev/null 2>&1; then
        echo ">>> ROS master 未运行，正在启动..."
        # 清理可能存在的roscore
        killall -9 roscore 2>/dev/null
        sleep 1
        
        # 在后台启动roscore
        nohup roscore > /tmp/roscore.log 2>&1 &
        sleep 3
    fi
    
    # ==== 4. 清理可能冲突的进程 ====
    echo ">>> 清理已有 foxglove 进程..."
    killall -9 foxglove_bridge 2>/dev/null
    sleep 1
    
    # ==== 5. 启动 foxglove bridge ====
    echo ">>> 启动 foxglove bridge 中..."
    
    # 清空日志文件
    > /tmp/foxglove.log
    
    # 在后台启动foxglove，并重定向日志
    nohup roslaunch foxglove_bridge foxglove_bridge.launch > /tmp/foxglove.log 2>&1 &
    
    local FOXGLOVE_PID=$!
    
    # 等待启动
    sleep 3
    
    # 检查是否启动成功
    if ps -p $FOXGLOVE_PID > /dev/null; then
        echo ">>> foxglove bridge 启动成功"
        echo ">>> 服务地址: ws://$ROS_IP:$FOXGLOVE_PORT"
        echo ">>> PID: $FOXGLOVE_PID"
        echo ">>> 日志文件: /tmp/foxglove.log"
        
        # 监控进程状态
        while ps -p $FOXGLOVE_PID > /dev/null; do
            sleep 1
        done
        
        # 进程已退出
        echo ">>> foxglove bridge 进程已退出"
        return 0
    else
        echo ">>> foxglove bridge 启动失败"
        echo ">>> 错误日志:"
        tail -20 /tmp/foxglove.log
        return 1
    fi
}

# ==== 主循环 ====
echo ">>> Foxglove Bridge 守护进程启动"
echo ">>> 重启策略: 无论什么原因退出都重启"
echo ">>> 重启延迟: ${RESTART_DELAY}秒"
echo ">>> 按 Ctrl+C 停止"

while true; do
    if $SHOULD_EXIT; then
        echo ">>> 正在退出守护进程..."
        break
    fi
    
    ((RESTART_COUNT++))
    
    # 启动foxglove
    start_foxglove $RESTART_COUNT
    
    # 如果不是第一次启动，显示重启信息
    if [ $RESTART_COUNT -gt 1 ]; then
        echo ">>> 重启次数: $RESTART_COUNT"
    fi
    
    echo ">>> 将在 $RESTART_DELAY 秒后重启..."
    
    # 倒计时，但允许被信号中断
    for i in $(seq $RESTART_DELAY -1 1); do
        if $SHOULD_EXIT; then
            break
        fi
        echo -ne ">>> 倒计时: ${i}秒 \r"
        sleep 1
    done
    echo
done

# 最终清理
cleanup