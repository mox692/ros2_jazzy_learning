# ROS 2 Jazzy + Web VNCのベースイメージ（ARM64対応）
FROM tiryoh/ros2-desktop-vnc:jazzy

# Gazebo Harmonicのリポジトリを追加
RUN sudo apt-get update && sudo apt-get install -y wget lsb-release gnupg curl \
    && sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

# パッケージリストの更新と、学習に必要なROS 2ツールのインストール
RUN sudo apt-get update && sudo apt-get install -y \
    ros-jazzy-turtlesim \
    ros-jazzy-rviz2 \
    ros-jazzy-ros-gz \
    ros-jazzy-slam-toolbox \
    ros-jazzy-xacro \
    ros-jazzy-joint-state-publisher-gui \
    gz-harmonic \
    openssh-server \
    && sudo rm -rf /var/lib/apt/lists/*

# SSHディレクトリの作成
RUN mkdir -p /var/run/sshd

# SSH設定の調整（パスワード認証を有効化）
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# supervisord設定を追加してSSHを自動起動
COPY sshd.conf /etc/supervisor/conf.d/sshd.conf

# コンテナ起動時のデフォルトディレクトリをワークスペースに設定
WORKDIR /home/ubuntu/yahboom_x3_ws
