#!/usr/bin/env bash
set -euo pipefail

# Run this on the Jetson/Wheeltec car for manual ROS 2 inspection commands.
# It opens a shell with the same FastDDS discovery environment as bringup.

ROS_SETUP="${ROS_SETUP:-/opt/ros/humble/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/wheeltec_ros2/install/setup.bash}"
DISCOVERY_SERVER="${ROS_DISCOVERY_SERVER:-100.64.0.4:11811}"
FAST_DDS_PROFILE="${FASTDDS_DEFAULT_PROFILES_FILE:-$HOME/fastdds_super_tailscale.xml}"

export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-0}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
export ROS_DISCOVERY_SERVER="$DISCOVERY_SERVER"
export FASTDDS_DEFAULT_PROFILES_FILE="$FAST_DDS_PROFILE"
export FASTRTPS_DEFAULT_PROFILES_FILE="${FASTRTPS_DEFAULT_PROFILES_FILE:-$FAST_DDS_PROFILE}"

if [[ ! -f "$ROS_SETUP" ]]; then
  echo "Missing ROS setup file: $ROS_SETUP" >&2
  exit 1
fi

if [[ ! -f "$WORKSPACE_SETUP" ]]; then
  echo "Missing Wheeltec workspace setup file: $WORKSPACE_SETUP" >&2
  exit 1
fi

if [[ ! -f "$FAST_DDS_PROFILE" ]]; then
  echo "Missing FastDDS profile: $FAST_DDS_PROFILE" >&2
  echo "Copy fastdds_super_tailscale.xml to the Jetson home directory first." >&2
  exit 1
fi

set +u
source "$ROS_SETUP"
source "$WORKSPACE_SETUP"
set -u

echo "Wheeltec ROS/Tailscale shell is ready"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: $ROS_DISCOVERY_SERVER"
echo "  fastdds profile: $FASTDDS_DEFAULT_PROFILES_FILE"
echo
echo "Useful checks:"
echo "  ros2 topic list -t --no-daemon"
echo "  ros2 topic echo /odom nav_msgs/msg/Odometry --once"
echo "  ros2 topic hz /odom"
echo "  ros2 topic echo /imu/data_raw sensor_msgs/msg/Imu --once"
echo "  ros2 topic hz /imu/data_raw"
echo "  ros2 topic echo /cmd_vel geometry_msgs/msg/Twist --no-daemon"

exec "${SHELL:-/bin/bash}" -l
