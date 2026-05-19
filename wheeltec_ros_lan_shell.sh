#!/usr/bin/env bash
set -euo pipefail

# Run this on the Jetson/Wheeltec car for LAN-mode ROS 2 inspection commands.

ROS_SETUP="${ROS_SETUP:-/opt/ros/humble/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/wheeltec_ros2/install/setup.bash}"

export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-0}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
unset ROS_DISCOVERY_SERVER
unset FASTDDS_DEFAULT_PROFILES_FILE
unset FASTRTPS_DEFAULT_PROFILES_FILE

if [[ ! -f "$ROS_SETUP" ]]; then
  echo "Missing ROS setup file: $ROS_SETUP" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE_SETUP" ]]; then
  echo "Missing Wheeltec workspace setup file: $WORKSPACE_SETUP" >&2
  exit 1
fi

set +u
source "$ROS_SETUP"
source "$WORKSPACE_SETUP"
set -u

echo "Wheeltec LAN ROS shell is ready"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: disabled"
echo "  fastdds profile: disabled"
echo
echo "Useful checks:"
echo "  ros2 topic list -t"
echo "  ros2 topic info /cmd_vel -v"
echo "  ros2 topic echo /cmd_vel geometry_msgs/msg/Twist --no-daemon"
echo "  ros2 topic echo /odom nav_msgs/msg/Odometry --once"

exec "${SHELL:-/bin/bash}" -l
