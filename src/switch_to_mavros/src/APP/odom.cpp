#include "odom.hpp"
#include <tf/transform_datatypes.h>
#include <geometry_msgs/Quaternion.h>
#include <nav_msgs/Odometry.h>
#include <mavros_msgs/PositionTarget.h>
#include <quadrotor_msgs/PositionCommand.h>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Matrix3x3.h>
#include <tf2_geometry_msgs/tf2_geometry_msgs.h>

// 创建发布器
ros::Publisher odom_pub;
ros::Publisher pos_target_pub;

void odom_callback(const nav_msgs::Odometry::ConstPtr& msg);
void pos_cmd_callback(const quadrotor_msgs::PositionCommand::ConstPtr& msg);
static void timer_5ms(void);

odom_structure odom_struct = 
{
    odom_callback,
    pos_cmd_callback,
    timer_5ms,
    0.0f,
    0.0f
};

PoseVel_Structure PoseVel = {0,0,0,0,0,0};

// 用于速度计算的变量（类似Python版本）
struct VelocityState {
    double prev_x, prev_y, prev_z;
    double prev_yaw;
    double prev_t;
    bool initialized;
    
    VelocityState() : prev_x(0), prev_y(0), prev_z(0), 
                      prev_yaw(0), prev_t(0), initialized(false) {}
};

VelocityState vel_state;

static void timer_5ms(void)
{
    // 5ms定时任务（如果需要）
}

// 回调函数 - 转发并转换odom数据
void odom_callback(const nav_msgs::Odometry::ConstPtr& msg)
{
    if (!odom_pub) return;
    
    // 直接复制整个消息
    nav_msgs::Odometry mavros_odom = *msg;
    
    // 只修改frame_id和child_frame_id
    mavros_odom.header.frame_id = "odom";
    mavros_odom.child_frame_id = "base_link";

    // 位置转换
    mavros_odom.pose.pose.position.y =  msg->pose.pose.position.x;
    mavros_odom.pose.pose.position.x = -msg->pose.pose.position.y;
    mavros_odom.pose.pose.position.z = msg->pose.pose.position.z;
    // 速度同样处理
    mavros_odom.twist.twist.linear.x =  msg->twist.twist.linear.x;
    mavros_odom.twist.twist.linear.y = msg->twist.twist.linear.y;
    mavros_odom.twist.twist.linear.z = msg->twist.twist.linear.z;

    // 四元数
    tf2::Quaternion q
    (
        msg->pose.pose.orientation.x,
        msg->pose.pose.orientation.y,
        msg->pose.pose.orientation.z,
        msg->pose.pose.orientation.w
    );

    // ENU → FRD（绕X或Z都可表达，但必须一致）
    tf2::Quaternion q_rot;
    q_rot.setRPY(0, 0, M_PI/2);  // FRD标准

    tf2::Quaternion q_new = q_rot * q;

    mavros_odom.pose.pose.orientation = tf2::toMsg(q_new);

    // ROS_INFO("%f\r\n",msg->pose.pose.orientation.z * 57.3);

    static unsigned int i=0;
    // if(++i >= 10)
    {
        i=0;
        // 发布到mavros
        odom_pub.publish(mavros_odom);
    }
}

// 回调函数2 - 转发位置指令到MAVROS
void pos_cmd_callback(const quadrotor_msgs::PositionCommand::ConstPtr& msg)
{
    if (!pos_target_pub) {
        ROS_WARN_THROTTLE(1.0, "Position target publisher not ready!");
        return;
    }
    
    // 创建 PositionTarget 消息
    mavros_msgs::PositionTarget target;
    
    // 设置时间戳和坐标系
    target.header.stamp = msg->header.stamp;
    target.header.frame_id = "map";
    target.coordinate_frame = mavros_msgs::PositionTarget::FRAME_LOCAL_NED;
    
    // type_mask = 0 表示启用所有控制（位置、速度、加速度、偏航）
    target.type_mask = 0;
    
    // 从规划消息中复制数据（根据 quadrotor_msgs/PositionCommand 的字段）
    // 位置
    // target.position.x = msg->position.x;
    // target.position.y = msg->position.y;
    // target.position.z = msg->position.z;
    target.position.x =  msg->position.x;
    target.position.y = -msg->position.y;
    target.position.z = -msg->position.z;
    
    // 速度
    target.velocity.x = msg->velocity.x;
    target.velocity.y = msg->velocity.y;
    target.velocity.z = msg->velocity.z;
    // target.velocity.x = 11;
    // target.velocity.y = 22;
    // target.velocity.z = 33;
    
    // 加速度
    target.acceleration_or_force.x = msg->acceleration.x;
    target.acceleration_or_force.y = msg->acceleration.y;
    target.acceleration_or_force.z = msg->acceleration.z;
    
    // 偏航和偏航速度（注意字段名可能是 yaw 和 yaw_dot）
    target.yaw = msg->yaw;
    target.yaw_rate = msg->yaw_dot;
    
    static unsigned int i=0;
    if(++i >= 10)
    {
        i=0;
        // 发布到 MAVROS
        pos_target_pub.publish(target);
    }
}
