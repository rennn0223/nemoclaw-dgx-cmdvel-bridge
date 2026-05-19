#!/usr/bin/env bash
set -euo pipefail

# DGX Spark LAN launcher.
# Use this when DGX and Wheeltec/Jetson cars are on the same Wi-Fi/LAN and
# `ros2 topic list` can already see the cars without ROS_DISCOVERY_SERVER.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROS_SETUP="${ROS_SETUP:-/opt/ros/jazzy/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/IsaacSim-ros_workspaces/jazzy_ws/install/setup.bash}"
BRIDGE_SCRIPT="${BRIDGE_SCRIPT:-$SCRIPT_DIR/dgx_cmd_vel_rest_api.py}"

export FLASK_HOST="${FLASK_HOST:-0.0.0.0}"
export FLASK_PORT="${FLASK_PORT:-5000}"
export CMD_VEL_TOPIC="${CMD_VEL_TOPIC:-/cmd_vel}"
export MAX_LINEAR_X="${MAX_LINEAR_X:-1.0}"
export MAX_ANGULAR_Z="${MAX_ANGULAR_Z:-1.0}"
export CMD_VEL_PUBLISH_HZ="${CMD_VEL_PUBLISH_HZ:-10}"

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

if [[ ! -f "$BRIDGE_SCRIPT" ]]; then
  echo "Missing bridge script: $BRIDGE_SCRIPT" >&2
  exit 1
fi

if ss -ltn 2>/dev/null | grep -q ":$FLASK_PORT "; then
  echo "REST port $FLASK_PORT is already in use."
  echo "Stop the old bridge first: pkill -f dgx_cmd_vel_rest_api.py" >&2
  exit 1
fi

set +u
source "$ROS_SETUP"
if [[ -f "$WORKSPACE_SETUP" ]]; then
  source "$WORKSPACE_SETUP"
else
  echo "Workspace setup not found, continuing without it: $WORKSPACE_SETUP" >&2
fi
set -u

echo "Starting DGX cmd_vel REST bridge in LAN mode"
echo "  host: $FLASK_HOST"
echo "  port: $FLASK_PORT"
echo "  topic: $CMD_VEL_TOPIC"
echo "  max linear_x: $MAX_LINEAR_X"
echo "  max angular_z: $MAX_ANGULAR_Z"
echo "  publish hz: $CMD_VEL_PUBLISH_HZ"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: disabled"
echo "  fastdds profile: disabled"
echo "  script: $BRIDGE_SCRIPT"

exec python3 "$BRIDGE_SCRIPT"
