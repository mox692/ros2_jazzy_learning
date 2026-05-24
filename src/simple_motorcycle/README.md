以下は、記事の環境を前提にした「最小構成」です。記事では ROS 2 Jazzy + Web VNC + Colima 環境を作り、Jazzy では Gazebo Classic ではなく Gazebo Harmonic / `ros_gz` を使う構成になっています。([Qiita][1])
ROS 2 ではノード同士が topic で通信するので、今回は `/cmd_vel` に速度指令を出してロボットを動かします。([ROS Documentation][2])

## ゴール

作るものはこれです。

* RViz2：簡易モーターサイクル風モデルを表示
* Gazebo：同じような簡易モデルをスポーン
* ROS 2：`/cmd_vel` に速度指令を publish
* Gazebo：`ros_gz_bridge` 経由で速度指令を受けて移動

厳密な二輪バイクは倒立・操舵・バランス制御が必要なので、最初は「見た目はバイク風、制御は差動二輪」という学習用モデルにします。

---

## 1. 追加パッケージを入れる

コンテナ内のターミナルで実行します。

```bash
sudo apt update
sudo apt install -y \
  ros-jazzy-robot-state-publisher \
  ros-jazzy-joint-state-publisher-gui \
  ros-jazzy-xacro \
  ros-jazzy-ros-gz \
  ros-jazzy-teleop-twist-keyboard
```

記事の Dockerfile でも `ros-jazzy-ros-gz`, `rviz2`, `xacro`, `joint-state-publisher-gui` を入れる前提になっていますが、足りない場合に備えて入れておきます。([Qiita][1])

---

## 2. ROS 2 パッケージを作る

```bash
cd ~/ros2_ws/src
ros2 pkg create simple_motorcycle --build-type ament_cmake
cd simple_motorcycle

mkdir -p launch urdf worlds rviz
```

---

## 3. `CMakeLists.txt` を置き換える

```bash
cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.8)
project(simple_motorcycle)

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY launch urdf worlds rviz
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
EOF
```

---

## 4. `package.xml` を置き換える

```bash
cat > package.xml <<'EOF'
<?xml version="1.0"?>
<package format="3">
  <name>simple_motorcycle</name>
  <version>0.0.1</version>
  <description>Simple motorcycle-like robot for ROS 2 Jazzy, RViz2, and Gazebo.</description>

  <maintainer email="you@example.com">you</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>

  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>joint_state_publisher_gui</exec_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>rviz2</exec_depend>
  <exec_depend>ros_gz_sim</exec_depend>
  <exec_depend>ros_gz_bridge</exec_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF
```

---

## 5. RViz2 用 URDF/Xacro を作る

```bash
cat > urdf/simple_motorcycle.urdf.xacro <<'EOF'
<?xml version="1.0"?>
<robot name="simple_motorcycle" xmlns:xacro="http://www.ros.org/wiki/xacro">

  <material name="blue">
    <color rgba="0.1 0.3 0.9 1.0"/>
  </material>

  <material name="black">
    <color rgba="0.02 0.02 0.02 1.0"/>
  </material>

  <material name="gray">
    <color rgba="0.5 0.5 0.5 1.0"/>
  </material>

  <link name="base_link">
    <visual>
      <origin xyz="0 0 0.45"/>
      <geometry>
        <box size="0.8 0.18 0.18"/>
      </geometry>
      <material name="blue"/>
    </visual>
  </link>

  <link name="front_wheel">
    <visual>
      <origin rpy="1.5708 0 0"/>
      <geometry>
        <cylinder radius="0.16" length="0.06"/>
      </geometry>
      <material name="black"/>
    </visual>
  </link>

  <joint name="front_wheel_joint" type="fixed">
    <parent link="base_link"/>
    <child link="front_wheel"/>
    <origin xyz="0.38 0 0.22"/>
  </joint>

  <link name="left_rear_wheel">
    <visual>
      <origin rpy="1.5708 0 0"/>
      <geometry>
        <cylinder radius="0.16" length="0.05"/>
      </geometry>
      <material name="black"/>
    </visual>
  </link>

  <joint name="left_rear_wheel_joint" type="fixed">
    <parent link="base_link"/>
    <child link="left_rear_wheel"/>
    <origin xyz="-0.32 0.09 0.22"/>
  </joint>

  <link name="right_rear_wheel">
    <visual>
      <origin rpy="1.5708 0 0"/>
      <geometry>
        <cylinder radius="0.16" length="0.05"/>
      </geometry>
      <material name="black"/>
    </visual>
  </link>

  <joint name="right_rear_wheel_joint" type="fixed">
    <parent link="base_link"/>
    <child link="right_rear_wheel"/>
    <origin xyz="-0.32 -0.09 0.22"/>
  </joint>

  <link name="handle">
    <visual>
      <origin xyz="0.35 0 0.65"/>
      <geometry>
        <box size="0.08 0.5 0.04"/>
      </geometry>
      <material name="gray"/>
    </visual>
  </link>

  <joint name="handle_joint" type="fixed">
    <parent link="base_link"/>
    <child link="handle"/>
    <origin xyz="0 0 0"/>
  </joint>

</robot>
EOF
```

---

## 6. Gazebo 用 SDF ワールドを作る

Gazebo Harmonic では `ros_gz_sim create` で SDF/URDF エンティティをスポーンできます。公式ドキュメントでも、`ros2 launch ros_gz_sim gz_sim.launch.py` で Gazebo を起動し、`ros2 run ros_gz_sim create ...` でモデルを投入する流れが説明されています。([ROS Documentation][3])

```bash
cat > worlds/motorcycle_world.sdf <<'EOF'
<?xml version="1.0" ?>
<sdf version="1.9">
  <world name="default">

    <plugin
      filename="gz-sim-physics-system"
      name="gz::sim::systems::Physics">
    </plugin>

    <plugin
      filename="gz-sim-scene-broadcaster-system"
      name="gz::sim::systems::SceneBroadcaster">
    </plugin>

    <light name="sun" type="directional">
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <specular>0.2 0.2 0.2 1</specular>
      <direction>-0.5 0.1 -0.9</direction>
    </light>

    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
        </visual>
      </link>
    </model>

    <model name="simple_motorcycle">
      <pose>0 0 0.2 0 0 0</pose>

      <link name="base_link">
        <inertial>
          <mass>5.0</mass>
          <inertia>
            <ixx>0.2</ixx>
            <iyy>0.4</iyy>
            <izz>0.4</izz>
          </inertia>
        </inertial>

        <collision name="body_collision">
          <pose>0 0 0.35 0 0 0</pose>
          <geometry>
            <box>
              <size>0.8 0.18 0.18</size>
            </box>
          </geometry>
        </collision>

        <visual name="body_visual">
          <pose>0 0 0.35 0 0 0</pose>
          <geometry>
            <box>
              <size>0.8 0.18 0.18</size>
            </box>
          </geometry>
          <material>
            <diffuse>0.1 0.3 0.9 1</diffuse>
          </material>
        </visual>

        <visual name="handle_visual">
          <pose>0.35 0 0.55 0 0 0</pose>
          <geometry>
            <box>
              <size>0.08 0.5 0.04</size>
            </box>
          </geometry>
          <material>
            <diffuse>0.5 0.5 0.5 1</diffuse>
          </material>
        </visual>
      </link>

      <link name="left_wheel">
        <pose>-0.3 0.12 0.16 1.5708 0 0</pose>
        <inertial>
          <mass>0.5</mass>
          <inertia>
            <ixx>0.01</ixx>
            <iyy>0.01</iyy>
            <izz>0.01</izz>
          </inertia>
        </inertial>
        <collision name="collision">
          <geometry>
            <cylinder>
              <radius>0.16</radius>
              <length>0.05</length>
            </cylinder>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <cylinder>
              <radius>0.16</radius>
              <length>0.05</length>
            </cylinder>
          </geometry>
          <material>
            <diffuse>0.02 0.02 0.02 1</diffuse>
          </material>
        </visual>
      </link>

      <link name="right_wheel">
        <pose>-0.3 -0.12 0.16 1.5708 0 0</pose>
        <inertial>
          <mass>0.5</mass>
          <inertia>
            <ixx>0.01</ixx>
            <iyy>0.01</iyy>
            <izz>0.01</izz>
          </inertia>
        </inertial>
        <collision name="collision">
          <geometry>
            <cylinder>
              <radius>0.16</radius>
              <length>0.05</length>
            </cylinder>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <cylinder>
              <radius>0.16</radius>
              <length>0.05</length>
            </cylinder>
          </geometry>
          <material>
            <diffuse>0.02 0.02 0.02 1</diffuse>
          </material>
        </visual>
      </link>

      <link name="front_wheel">
        <pose>0.35 0 0.16 1.5708 0 0</pose>
        <visual name="visual">
          <geometry>
            <cylinder>
              <radius>0.16</radius>
              <length>0.06</length>
            </cylinder>
          </geometry>
          <material>
            <diffuse>0.02 0.02 0.02 1</diffuse>
          </material>
        </visual>
      </link>

      <joint name="left_wheel_joint" type="revolute">
        <parent>base_link</parent>
        <child>left_wheel</child>
        <axis>
          <xyz>0 1 0</xyz>
        </axis>
      </joint>

      <joint name="right_wheel_joint" type="revolute">
        <parent>base_link</parent>
        <child>right_wheel</child>
        <axis>
          <xyz>0 1 0</xyz>
        </axis>
      </joint>

      <joint name="front_wheel_joint" type="fixed">
        <parent>base_link</parent>
        <child>front_wheel</child>
      </joint>

      <plugin
        filename="gz-sim-diff-drive-system"
        name="gz::sim::systems::DiffDrive">
        <left_joint>left_wheel_joint</left_joint>
        <right_joint>right_wheel_joint</right_joint>
        <wheel_separation>0.24</wheel_separation>
        <wheel_radius>0.16</wheel_radius>
        <topic>cmd_vel</topic>
        <odom_topic>odom</odom_topic>
        <frame_id>odom</frame_id>
        <child_frame_id>base_link</child_frame_id>
      </plugin>

    </model>
  </world>
</sdf>
EOF
```

---

## 7. launch ファイルを作る

```bash
cat > launch/sim.launch.py <<'EOF'
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
EOF
```

---

## 8. ビルドする

```bash
cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

毎回ターミナルを開くたびに必要なので、面倒なら：

```bash
echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc
```

---

## 9. Gazebo + RViz2 を起動する

```bash
ros2 launch simple_motorcycle sim.launch.py
```

起動したら：

### Gazebo 側

モデルが地面上に出ます。

### RViz2 側

左下の `Add` から：

1. `RobotModel` を追加
2. `Fixed Frame` を `base_link` に変更

これで簡易モデルが見えます。

---

## 10. ROS 2 から動かす

別ターミナルを開いて：

```bash
cd ~/ros2_ws
source install/setup.bash
```

前進：

```bash
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.5}, angular: {z: 0.0}}" -r 10
```

旋回：

```bash
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.2}, angular: {z: 0.8}}" -r 10
```

停止：

```bash
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist \
"{linear: {x: 0.0}, angular: {z: 0.0}}" -1
```

キーボードで動かす場合：

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

---

## 11. ROS 2 の基本確認コマンド

ROS 2 の基本操作として、まずこのあたりを触ると理解しやすいです。ROS 2 の topic は、ノード間でデータを交換するためのバスのような仕組みです。([ROS Documentation][2])

```bash
ros2 node list
```

```bash
ros2 topic list
```

```bash
ros2 topic echo /cmd_vel
```

```bash
ros2 topic info /cmd_vel
```

```bash
ros2 interface show geometry_msgs/msg/Twist
```

---

## うまく動かないとき

### `/cmd_vel` を publish しても動かない

まず bridge がいるか確認します。

```bash
ros2 node list
```

`parameter_bridge` が出ていなければ、別ターミナルで手動起動します。

```bash
ros2 run ros_gz_bridge parameter_bridge \
/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist
```

### Gazebo が重い

記事でも Gazebo/RViz2 は GUI ツールなので、CPU とメモリを多めに割り当てる構成になっています。Colima 起動時は少なくとも以下くらいが無難です。([Qiita][1])

```bash
colima stop
colima start --cpu 4 --memory 8 --vm-type vz
```

### RViz2 にモデルが出ない

RViz2 の `Fixed Frame` を `base_link` にしてください。
また、以下で `robot_description` が出るか確認できます。

```bash
ros2 param get /robot_state_publisher robot_description
```

---

次に発展させるなら、順番としては「URDF と SDF を共通化する」「車輪を本当に回転表示する」「Ackermann steering にする」「センサー LiDAR / camera を載せる」の順が良いです。

[1]: https://qiita.com/Toshiaki0315/items/e5866e737ff866aaa80e "MacでROS 2 Jazzy学習環境を構築する（Colima + Web VNC） #container - Qiita"
[2]: https://docs.ros.org/en/jazzy/Tutorials/Beginner-CLI-Tools/Understanding-ROS2-Topics/Understanding-ROS2-Topics.html?utm_source=chatgpt.com "Understanding topics — ROS 2 Documentation: Jazzy ..."
[3]: https://docs.ros.org/en/jazzy/p/ros_gz_sim/?utm_source=chatgpt.com "ros_gz_sim: Jazzy 1.0.22 documentation"
