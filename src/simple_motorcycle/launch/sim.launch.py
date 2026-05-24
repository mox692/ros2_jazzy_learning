from launch import LaunchDescription
from launch.actions import ExecuteProcess
from launch_ros.actions import Node
from launch.substitutions import Command, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    pkg = FindPackageShare('simple_motorcycle')

    xacro_file = PathJoinSubstitution([
        pkg, 'urdf', 'simple_motorcycle.urdf.xacro'
    ])

    world_file = PathJoinSubstitution([
        pkg, 'worlds', 'motorcycle_world.sdf'
    ])

    robot_description = {
        'robot_description': Command(['xacro ', xacro_file])
    }

    return LaunchDescription([
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            parameters=[robot_description],
            output='screen'
        ),

        ExecuteProcess(
            cmd=['gz', 'sim', '-r', world_file],
            output='screen'
        ),

        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'
            ],
            output='screen'
        ),

        Node(
            package='rviz2',
            executable='rviz2',
            output='screen'
        ),
    ])
