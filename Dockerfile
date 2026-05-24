# ROS 2 Humble + Web VNCのベースイメージ（ARM64対応）
FROM tiryoh/ros2-desktop-vnc:humble

# パッケージリストの更新と、学習に必要なROS 2ツールのインストール
RUN sudo apt-get update && sudo apt-get install -y \
    ros-humble-turtlesim \
    ros-humble-rviz2 \
    ros-humble-ros-gz \
    ros-humble-slam-toolbox \
    ros-humble-xacro \
    ros-humble-joint-state-publisher-gui \
    && sudo rm -rf /var/lib/apt/lists/*

# コンテナ起動時のデフォルトディレクトリをワークスペースに設定
WORKDIR /home/ubuntu/yahboom_x3_ws
