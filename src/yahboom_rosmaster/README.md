Fork repo: https://github.com/automaticaddison/yahboom_rosmaster

# yahboom_rosmaster #
![OS](https://img.shields.io/ubuntu/v/ubuntu-wallpapers/noble)
![ROS_2](https://img.shields.io/ros/v/jazzy/rclcpp)

Automatic Addison support for the ROSMASTER X3 mecanum wheel robot robot by Yahboom - ROS 2

![ROSMASTER X3 in Gazebo](https://automaticaddison.com/wp-content/uploads/2024/11/gazebo-800-square-mecanum-controller.gif)

![ROSMASTER X3 in RViz](https://automaticaddison.com/wp-content/uploads/2024/11/rviz-800-square-mecanum-controller.gif)



# Setup

## 1. Clone the Repository

First, navigate to your workspace.

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
```

Clone the repository.

```bash
git clone https://github.com/automaticaddison/yahboom_rosmaster.git
```

The expected directory structure will be as follows.

```text
~/ros2_ws/src/
└── yahboom_rosmaster/
    ├── mecanum_drive_controller/
    ├── yahboom_rosmaster/
    ├── yahboom_rosmaster_bringup/
    ├── yahboom_rosmaster_description/
    ├── yahboom_rosmaster_gazebo/
    ├── yahboom_rosmaster_navigation/
    └── ...
```

---

## 2. Install Dependencies

Since your environment is assumed to be ROS 2 Jazzy + Gazebo Harmonic, install at least the following packages.

```bash
sudo apt update
sudo apt install -y \
  python3-rosdep \
  python3-colcon-common-extensions \
  ros-jazzy-xacro \
  ros-jazzy-rviz2 \
  ros-jazzy-robot-state-publisher \
  ros-jazzy-joint-state-publisher \
  ros-jazzy-joint-state-publisher-gui \
  ros-jazzy-ros-gz \
  ros-jazzy-gz-ros2-control \
  ros-jazzy-ros2-control \
  ros-jazzy-ros2-controllers \
  ros-jazzy-controller-manager \
  ros-jazzy-joint-state-broadcaster
```

Only run this if you haven't initialized `rosdep` before.

```bash
sudo rosdep init
rosdep update
```

If `rosdep` is already initialized, `sudo rosdep init` will fail with an error, but you can safely ignore it.

---

## 3. Resolve Dependencies

```bash
cd ~/ros2_ws
rosdep install --from-paths src --ignore-src -r -y
```

This repository uses ROS 2 Control and Gazebo. The Automatic Addison tutorial also demonstrates how to simulate a mecanum wheel robot using Gazebo and ROS 2 Control. ([Automatic Addison][2])

---

## 4. Build the Workspace

```bash
cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

Verify that the build succeeded.

```bash
ros2 pkg list | grep yahboom
```

Expected output:

```text
yahboom_rosmaster
yahboom_rosmaster_bringup
yahboom_rosmaster_description
yahboom_rosmaster_gazebo
yahboom_rosmaster_navigation
...
```

Also check for the mecanum controller package.

```bash
ros2 pkg list | grep mecanum
```

---

## 5. Launch ROSMASTER X3 in Gazebo

The easiest way is to use the provided launch script.

```bash
bash ~/ros2_ws/src/yahboom_rosmaster/yahboom_rosmaster_bringup/scripts/rosmaster_x3_gazebo.sh
```

This script internally calls the following launch file. ([GitHub][3])

```bash
ros2 launch yahboom_rosmaster_gazebo yahboom_rosmaster.gazebo.launch.py \
  enable_odom_tf:=true \
  headless:=False \
  load_controllers:=true \
  world_file:=cafe.world \
  use_rviz:=true \
  use_robot_state_pub:=true \
  use_sim_time:=true \
  x:=0.0 \
  y:=0.0 \
  z:=0.20 \
  roll:=0.0 \
  pitch:=0.0 \
  yaw:=0.0
```

The script specifies parameters like `world_file:=cafe.world`, `use_rviz:=true`, `load_controllers:=true`, `use_sim_time:=true` to launch Gazebo + RViz2 + controllers together. ([GitHub][3])

---

## 6. Launching Directly (Without Script)

To launch directly without using the script, use this command.

```bash
ros2 launch yahboom_rosmaster_gazebo yahboom_rosmaster.gazebo.launch.py \
  enable_odom_tf:=true \
  headless:=False \
  load_controllers:=true \
  world_file:=cafe.world \
  use_rviz:=true \
  use_robot_state_pub:=true \
  use_sim_time:=true \
  x:=0.0 \
  y:=0.0 \
  z:=0.20 \
  roll:=0.0 \
  pitch:=0.0 \
  yaw:=0.0
```

To reduce resource usage, you can disable RViz2.

```bash
ros2 launch yahboom_rosmaster_gazebo yahboom_rosmaster.gazebo.launch.py \
  enable_odom_tf:=true \
  headless:=False \
  load_controllers:=true \
  world_file:=empty.world \
  use_rviz:=false \
  use_robot_state_pub:=true \
  use_sim_time:=true \
  x:=0.0 \
  y:=0.0 \
  z:=0.05 \
  roll:=0.0 \
  pitch:=0.0 \
  yaw:=0.0
```

For `cafe.world`, the script comments specify `z:=0.20`. For `house.world`, it's commented as `z:=0.05`. ([GitHub][3])

---

## 7. Verification After Launch

Open a new terminal:

```bash
cd ~/ros2_ws
source install/setup.bash
```

Check ROS 2 topics.

```bash
ros2 topic list
```

Also check Gazebo topics.

```bash
gz topic -l
```

The Automatic Addison tutorial also demonstrates verification steps after launch using `ros2 topic list`, `gz topic -l`, and `ros2 control list_controllers`. ([Automatic Addison][2])

Check the controllers.

```bash
ros2 control list_controllers
```

The expected output should be approximately as follows.

```text
joint_state_broadcaster
mecanum_drive_controller
```

---

## 8. Moving the Robot

This repository uses a mecanum wheel controller. As explained in the Automatic Addison tutorial, the mecanum controller receives velocity commands like `/cmd_vel` and converts them to individual wheel velocities. ([Automatic Addison][2])

First, find the topic name.

```bash
ros2 topic list | grep cmd
```

Depending on your environment, you might see topics like:

```text
/mecanum_drive_controller/cmd_vel
/cmd_vel
```

Check the message type.

```bash
ros2 topic info /mecanum_drive_controller/cmd_vel
```

If it's `geometry_msgs/msg/TwistStamped`, move forward with this command.

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.1, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}}" \
--rate 5
```

Lateral movement (mecanum-specific):

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.0, y: 0.1, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}}" \
--rate 5
```

Rotation:

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.4}}}" \
--rate 5
```

To stop, press `Ctrl + C` and then send a zero velocity command once.

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}}" \
--once
```

---

## 9. Understanding the Flow

The flow is as follows:

```text
yahboom_rosmaster_description
  └── URDF/Xacro
        │
        v
robot_state_publisher
        │
        v
/tf, /robot_description

yahboom_rosmaster_gazebo
  └── Gazebo world + robot spawn
        │
        v
ROSMASTER X3 model generated in Gazebo

mecanum_drive_controller
  └── Receives /mecanum_drive_controller/cmd_vel
        │
        v
Sends velocity commands to 4 mecanum wheel joints

Gazebo physics
  └── Robot moves
```

The overall architecture looks like this:

```text
                     ROS 2 side
┌─────────────────────────────────────────────────────┐
│                                                     │
│  ros2 topic pub                                     │
│  or your node                                       │
│      │                                              │
│      │ /mecanum_drive_controller/cmd_vel            │
│      │ geometry_msgs/msg/TwistStamped               │
│      v                                              │
│  mecanum_drive_controller                           │
│      │                                              │
│      │ wheel joint commands                         │
│      v                                              │
│  ros2_control controller_manager                    │
│      │                                              │
└──────┼──────────────────────────────────────────────┘
       │
       v
                     Gazebo side
┌─────────────────────────────────────────────────────┐
│                                                     │
│  gz_ros2_control plugin                             │
│      │                                              │
│      v                                              │
│  Gazebo simulated joints                            │
│      │                                              │
│      v                                              │
│  ROSMASTER X3 model moves                           │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 10. Common Errors

### `Package 'yahboom_rosmaster_gazebo' not found`

You likely haven't sourced your workspace.

```bash
cd ~/ros2_ws
source install/setup.bash
```

Verify:

```bash
ros2 pkg list | grep yahboom_rosmaster_gazebo
```

---

### `gz_ros2_control` not found

Install the package.

```bash
sudo apt install -y ros-jazzy-gz-ros2-control
```

Then rebuild.

```bash
cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

---

### Controller is inactive

Check:

```bash
ros2 control list_controllers
```

To manually activate:

```bash
ros2 control switch_controllers \
  --activate mecanum_drive_controller \
  --activate joint_state_broadcaster
```

---

### Gazebo is slow/heavy

It's recommended to use `empty.world` instead of `cafe.world` initially.

```bash
ros2 launch yahboom_rosmaster_gazebo yahboom_rosmaster.gazebo.launch.py \
  enable_odom_tf:=true \
  headless:=False \
  load_controllers:=true \
  world_file:=empty.world \
  use_rviz:=false \
  use_robot_state_pub:=true \
  use_sim_time:=true \
  x:=0.0 y:=0.0 z:=0.05 roll:=0.0 pitch:=0.0 yaw:=0.0
```

---

## Quick Start Command Summary

```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src
git clone https://github.com/automaticaddison/yahboom_rosmaster.git

cd ~/ros2_ws
sudo apt update && rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash

bash ~/ros2_ws/src/yahboom_rosmaster/yahboom_rosmaster_bringup/scripts/rosmaster_x3_gazebo.sh
```

After launch, in a new terminal:

```bash
cd ~/ros2_ws
source install/setup.bash

ros2 topic list
ros2 control list_controllers
```

Move the robot:

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.1, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}}" \
--rate 5
```

Stop:

```bash
ros2 topic pub /mecanum_drive_controller/cmd_vel geometry_msgs/msg/TwistStamped \
"{header: {stamp: now, frame_id: 'base_link'}, twist: {linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}}" \
--once
```

With these steps, you can launch the ROSMASTER X3 model from `automaticaddison/yahboom_rosmaster` in Gazebo and control it from ROS 2.

[1]: https://github.com/automaticaddison/yahboom_rosmaster "GitHub - automaticaddison/yahboom_rosmaster: Automatic Addison support for the ROSMASTER X3 mobile robot by Yahboom - ROS 2 · GitHub"
[2]: https://automaticaddison.com/how-to-simulate-a-mobile-robot-in-gazebo-ros-2-jazzy/ "How to Simulate a Mobile Robot in Gazebo – ROS 2 Jazzy"
[3]: https://github.com/automaticaddison/yahboom_rosmaster/blob/main/yahboom_rosmaster_bringup/scripts/rosmaster_x3_gazebo.sh "yahboom_rosmaster/yahboom_rosmaster_bringup/scripts/rosmaster_x3_gazebo.sh at main · automaticaddison/yahboom_rosmaster · GitHub"
