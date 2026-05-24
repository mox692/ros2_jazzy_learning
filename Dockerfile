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
