# ROS 2 Jazzy Learning Environment

Docker-based ROS 2 Humble development environment with Web VNC and SSH access.

## Features

- ROS 2 Humble Desktop
- Web VNC access on port 6080
- SSH access on port 2222
- Pre-installed ROS 2 packages:
  - turtlesim
  - rviz2
  - ros-gz
  - slam-toolbox
  - xacro
  - joint-state-publisher-gui

## Quick Start

```bash
# Build the Docker image
docker-compose build

# Start the container
docker-compose up -d

# Stop the container
docker-compose down
```

## Access Methods

### Web VNC
Open your browser and navigate to:
```
http://localhost:6080
```

### SSH
Connect via SSH from your host machine:
```bash
ssh -p 2222 ubuntu@localhost
```
**Username:** `ubuntu`
**Password:** `ubuntu`

## Workspace

The `./src` directory on your host is mounted to `/home/ubuntu/ros2_ws/src` inside the container for shared development.
