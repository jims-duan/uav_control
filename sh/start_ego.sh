#!/bin/bash

source /opt/ros/noetic/setup.bash

source /home/nano/ROS/catkin_ego/devel/setup.bash

timeout 5 rostopic pub -r 100 /planning/pos_cmd quadrotor_msgs/PositionCommand \
"header: {seq: 1, stamp: now, frame_id: 'world'}
position: {x: 0.0, y: 0.0, z: 0.4}
velocity: {x: 0.0, y: 0.0, z: 0.0}
acceleration: {x: 0.0, y: 0.0, z: 0.0}
yaw: 0.0
yaw_dot: 0.0
kx: [0.0, 0.0, 0.0]
kv: [0.0, 0.0, 0.0]
trajectory_id: 39
trajectory_flag: 1" 2>/dev/null

# sleep 3

# roslaunch ego_planner test.launch

