#!/usr/bin/env bash
set -euo pipefail

# Run this on the Jetson/Wheeltec car when it is on the same Wi-Fi/LAN as DGX.

ROS_SETUP="${ROS_SETUP:-/opt/ros/humble/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/wheeltec_ros2/install/setup.bash}"
LAUNCH_PACKAGE="${LAUNCH_PACKAGE:-turn_on_wheeltec_robot}"
LAUNCH_FILE="${LAUNCH_FILE:-turn_on_wheeltec_robot.launch.py}"

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

echo "Starting Wheeltec robot bringup in LAN mode"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: disabled"
echo "  fastdds profile: disabled"
echo "  launch: $LAUNCH_PACKAGE $LAUNCH_FILE"

exec ros2 launch "$LAUNCH_PACKAGE" "$LAUNCH_FILE"
