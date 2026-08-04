#include <ros/ros.h>
#include <mavros_msgs/RCIn.h>
#include <std_msgs/Empty.h>
#include <mavros_msgs/CommandLong.h>
#include <geometry_msgs/PoseStamped.h>

class RcControlNode {
private:
    ros::Subscriber rc_sub;
    ros::Publisher return_home_pub;
    ros::Publisher resume_explore_pub;
    ros::Publisher move_base_goal_pub;
    ros::ServiceClient reboot_client;
    
    // 记录通道6上次的状态，初始值为1500（中立位置）
    int last_channel_6_state = 1500;
    // 记录通道9上次的状态，初始值为1500（中立位置）
    int last_channel_9_state = 1500;
    // 记录通道11（索引10）上次的状态，初始值为1500（中立位置）
    int last_channel_11_state = 1500;
    
public:
    RcControlNode(ros::NodeHandle& nh) {
        rc_sub = nh.subscribe("/mavros/rc/in", 10, &RcControlNode::rcCallback, this);
        reboot_client = nh.serviceClient<mavros_msgs::CommandLong>("/mavros/cmd/command");
        ROS_INFO("RC Control Node initialized, listening to /mavros/rc/in");
        
        return_home_pub = nh.advertise<std_msgs::Empty>("/planning/return_home", 10);
        resume_explore_pub = nh.advertise<std_msgs::Empty>("/planning/resume_explore", 10);
        move_base_goal_pub = nh.advertise<geometry_msgs::PoseStamped>("/move_base_simple/goal", 10);
    }
    
    void rebootFlightController()
    {
        mavros_msgs::CommandLong reboot_cmd;
        reboot_cmd.request.command = 246;  // MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN
        reboot_cmd.request.param1 = 1;     // 1 = 重启飞控
        reboot_cmd.request.param2 = 0;
        reboot_cmd.request.param3 = 0;
        reboot_cmd.request.param4 = 0;
        reboot_cmd.request.param5 = 0;
        reboot_cmd.request.param6 = 0;
        reboot_cmd.request.param7 = 0;
        
        if(reboot_client.call(reboot_cmd))
        {
            if(reboot_cmd.response.success)
            {
                ROS_INFO("飞控复位命令已发送，飞控将重启");
            }
            else
            {
                ROS_WARN("飞控复位命令发送失败");
            }
        }
        else
        {
            ROS_ERROR("无法调用飞控复位服务，请检查MAVROS是否运行");
        }
    }

    void rcCallback(const mavros_msgs::RCIn::ConstPtr& msg)
    {
        // 检查通道6（索引5）的状态变化
        if(msg->channels[5] == 1048 && last_channel_6_state != 1048)
        {
            ROS_INFO("复位飞控");
            rebootFlightController();
        }

        // 检查通道9（索引8）的状态变化
        if(msg->channels[8] == 1048 && last_channel_9_state != 1048)
        {
            ROS_INFO("左 - 发布返航指令");
            std_msgs::Empty empty_msg;
            
            for(int i = 0; i < 3; i++) {
                return_home_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
            }
        }
        else if(msg->channels[8] == 1946 && last_channel_9_state != 1946)
        {
            ROS_INFO("右 - 发布继续探索指令");
            std_msgs::Empty empty_msg;
            for(int i = 0; i < 3; i++) {
                resume_explore_pub.publish(empty_msg);
                ros::Duration(0.05).sleep();
            }
        }
        
        // 通道11（索引10）逻辑 - 当值为1948时发布点，值为1048时停止
        // 注意：channels[10] 对应遥控器的通道11（因为数组从0开始）
        int ch11_value = msg->channels[10];
        
        if(ch11_value == 1946 && last_channel_11_state != 1946)
        {
            ROS_INFO("通道11 = 1948，发布导航点到Rviz");
            publishMoveBaseGoal();  // 切换到1948时发布一次点
        }
        else if(ch11_value == 1048 && last_channel_11_state != 1048)
        {
            ROS_INFO("通道11 = 1048，停止发布点");
            // 这里可以添加停止导航的逻辑（如果需要）

        }
        
        // 更新上次状态
        last_channel_6_state = msg->channels[5];
        last_channel_9_state = msg->channels[8];
        last_channel_11_state = msg->channels[10];
    }
    
    void publishMoveBaseGoal()
    {
        geometry_msgs::PoseStamped goal_msg;
        
        // 设置时间戳
        goal_msg.header.stamp = ros::Time::now();
        // 设置坐标系（可以根据需要修改）
        goal_msg.header.frame_id = "map";
        
        // 设置点的坐标（这里使用原点作为示例，你可以根据需要修改）
        goal_msg.pose.position.x = 0.0;
        goal_msg.pose.position.y = 0.0;
        goal_msg.pose.position.z = 0.0;
        
        // 设置朝向（四元数，这里设置为朝向x轴正方向）
        goal_msg.pose.orientation.x = 0.0;
        goal_msg.pose.orientation.y = 0.0;
        goal_msg.pose.orientation.z = 0.0;
        goal_msg.pose.orientation.w = 1.0;
        
        // 发布点
        move_base_goal_pub.publish(goal_msg);
        
        ROS_INFO("发布导航点到Rviz: [%.2f, %.2f, %.2f]", 
                 goal_msg.pose.position.x, 
                 goal_msg.pose.position.y, 
                 goal_msg.pose.position.z);
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