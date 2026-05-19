#!/usr/bin/env bash
set -euo pipefail

# Run this on the Jetson/Wheeltec car.
# It loads ROS 2 Humble, connects to the DGX FastDDS discovery server,
# and launches the Wheeltec robot bringup.

ROS_SETUP="${ROS_SETUP:-/opt/ros/humble/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/wheeltec_ros2/install/setup.bash}"
DISCOVERY_SERVER="${ROS_DISCOVERY_SERVER:-100.64.0.4:11811}"
FAST_DDS_PROFILE="${FASTDDS_DEFAULT_PROFILES_FILE:-$HOME/fastdds_super_tailscale.xml}"
LAUNCH_PACKAGE="${LAUNCH_PACKAGE:-turn_on_wheeltec_robot}"
LAUNCH_FILE="${LAUNCH_FILE:-turn_on_wheeltec_robot.launch.py}"

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

echo "Starting Wheeltec robot bringup"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: $ROS_DISCOVERY_SERVER"
echo "  fastdds profile: $FASTDDS_DEFAULT_PROFILES_FILE"
echo "  launch: $LAUNCH_PACKAGE $LAUNCH_FILE"

exec ros2 launch "$LAUNCH_PACKAGE" "$LAUNCH_FILE"
