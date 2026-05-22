#include <ros/ros.h>
#include <mavros_msgs/RCIn.h>
#include <std_msgs/Empty.h>
#include <geometry_msgs/PoseStamped.h>

class RcControlNode {
private:
    ros::Subscriber rc_sub;
    ros::Publisher return_home_pub;
    ros::Publisher resume_explore_pub;
    ros::Publisher goal_pub;

    // 记录通道9上次的状态，初始值为1500（中立位置）
    int last_channel_9_state = 1500;
    // 记录通道10上次的状态，初始值为1500（中立位置）
    int last_channel_10_state = 1500;
    
public:
    RcControlNode(ros::NodeHandle& nh) {
        // 订阅RC输入话题
        rc_sub = nh.subscribe("/mavros/rc/in", 10, &RcControlNode::rcCallback, this);
        ROS_INFO("RC Control Node initialized, listening to /mavros/rc/in");

        // 发布返航指令话题
        return_home_pub = nh.advertise<std_msgs::Empty>("/planning/return_home", 10);
        // 发布继续探索指令话题
        resume_explore_pub = nh.advertise<std_msgs::Empty>("/planning/resume_explore", 10);
        // 发布导航目标点话题
        goal_pub = nh.advertise<geometry_msgs::PoseStamped>("/move_base_simple/goal", 10);
        
        ROS_INFO("Target position for channel 10: (1.00, 1.00, 1.00)");
    }
    
    void publishGoal() {
        geometry_msgs::PoseStamped goal_msg;
        
        // 设置时间戳和坐标系
        goal_msg.header.stamp = ros::Time::now();
        goal_msg.header.frame_id = "map";  // 使用map坐标系
        
        // 设置目标位置为 (1, 1, 1)
        goal_msg.pose.position.x = 1.0;
        goal_msg.pose.position.y = 1.0;
        goal_msg.pose.position.z = 1.0;
        
        // 设置目标方向（四元数，使用默认朝向）
        goal_msg.pose.orientation.x = 0.0;
        goal_msg.pose.orientation.y = 0.0;
        goal_msg.pose.orientation.z = 0.0;
        goal_msg.pose.orientation.w = 1.0;
        
        // 连续发布3次以确保接收
        for(int i = 0; i < 3; i++) {
            goal_pub.publish(goal_msg);
            ros::Duration(0.05).sleep();
        }
        
        ROS_INFO("Goal published via channel 10: (1.00, 1.00, 1.00)");
    }
    
    void rcCallback(const mavros_msgs::RCIn::ConstPtr& msg)
    {
        // 确保至少有9个通道（通道9）
        if(msg->channels.size() >= 9) {
            // 通道9控制返航/继续探索
            if(msg->channels[8] == 1048 && last_channel_9_state != 1048)
            {
                ROS_INFO("左");
                std_msgs::Empty empty_msg;
                
                return_home_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
                return_home_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
                return_home_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
            }
            else if(msg->channels[8] == 1946 && last_channel_9_state != 1946)
            {
                ROS_INFO("右");
                std_msgs::Empty empty_msg;
                resume_explore_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
                resume_explore_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
                resume_explore_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
            }
            
            last_channel_9_state = msg->channels[8];
        }
        
        // 确保至少有10个通道（通道10）
        if(msg->channels.size() >= 10) {
            int current_state = msg->channels[9];  // 通道10（索引9）
            
            // 检测通道10从非触发值变为触发值（上升沿触发）
            if(current_state == 1048 && last_channel_10_state != 1048)
            {
                ROS_INFO("Channel 10 triggered (value: 1048) - publishing goal to (1,1,1)");
                publishGoal();
            }
            else if(current_state == 1946 && last_channel_10_state != 1946)
            {
                ROS_INFO("Channel 10 triggered (value: 1946) - publishing goal to (1,1,1)");
                publishGoal();
            }
            
            last_channel_10_state = current_state;
        }
    }
};

int main(int argc, char** argv) {
    // 设置中文编码（针对终端输出）
    setlocale(LC_ALL, "zh_CN.UTF-8");
    
    // 初始化 ROS 节点
    ros::init(argc, argv, "rc_control_node");
    
    // 创建 NodeHandle
    ros::NodeHandle nh;
    
    // 创建类实例（内部订阅话题）
    RcControlNode node(nh);
    
    // 循环等待回调，保持节点运行
    ros::spin();
    
    return 0;
}