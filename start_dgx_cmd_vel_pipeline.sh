#!/usr/bin/env bash
set -euo pipefail

# One-command DGX Spark launcher:
# 1. Start FastDDS discovery server on the Tailscale IP.
# 2. Start the REST bridge that publishes ROS 2 /cmd_vel.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROS_SETUP="${ROS_SETUP:-/opt/ros/jazzy/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/IsaacSim-ros_workspaces/jazzy_ws/install/setup.bash}"
BRIDGE_SCRIPT="${BRIDGE_SCRIPT:-$SCRIPT_DIR/dgx_cmd_vel_rest_api.py}"
DISCOVERY_HOST="${DISCOVERY_HOST:-100.64.0.4}"
DISCOVERY_PORT="${DISCOVERY_PORT:-11811}"
DISCOVERY_ID="${DISCOVERY_ID:-0}"

export FLASK_HOST="${FLASK_HOST:-0.0.0.0}"
export FLASK_PORT="${FLASK_PORT:-5000}"
export CMD_VEL_TOPIC="${CMD_VEL_TOPIC:-/cmd_vel}"
export MAX_LINEAR_X="${MAX_LINEAR_X:-1.0}"
export MAX_ANGULAR_Z="${MAX_ANGULAR_Z:-1.0}"
export CMD_VEL_PUBLISH_HZ="${CMD_VEL_PUBLISH_HZ:-10}"

export ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}"
export ROS_LOCALHOST_ONLY="${ROS_LOCALHOST_ONLY:-0}"
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
export ROS_DISCOVERY_SERVER="${ROS_DISCOVERY_SERVER:-$DISCOVERY_HOST:$DISCOVERY_PORT}"
export FASTDDS_DEFAULT_PROFILES_FILE="${FASTDDS_DEFAULT_PROFILES_FILE:-$HOME/fastdds_super_tailscale.xml}"
export FASTRTPS_DEFAULT_PROFILES_FILE="${FASTRTPS_DEFAULT_PROFILES_FILE:-$HOME/fastdds_super_tailscale.xml}"

DISCOVERY_PID=""

cleanup() {
  if [[ -n "$DISCOVERY_PID" ]] && kill -0 "$DISCOVERY_PID" 2>/dev/null; then
    echo "Stopping FastDDS discovery server pid $DISCOVERY_PID"
    kill "$DISCOVERY_PID" 2>/dev/null || true
    wait "$DISCOVERY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    echo "Missing $label: $path" >&2
    exit 1
  fi
}

require_file "$ROS_SETUP" "ROS setup file"
require_file "$BRIDGE_SCRIPT" "bridge script"

if ss -lun 2>/dev/null | grep -q ":$DISCOVERY_PORT "; then
  echo "FastDDS discovery port $DISCOVERY_PORT is already in use."
  echo "Stop the old discovery server first, or set DISCOVERY_PORT to another value." >&2
  exit 1
fi

if ss -ltn 2>/dev/null | grep -q ":$FLASK_PORT "; then
  echo "REST port $FLASK_PORT is already in use."
  echo "Stop the old bridge first: pkill -f dgx_cmd_vel_rest_api.py" >&2
  exit 1
fi

set +u
source "$ROS_SETUP"
set -u

echo "Starting FastDDS discovery server"
echo "  host: $DISCOVERY_HOST"
echo "  port: $DISCOVERY_PORT"
echo "  id: $DISCOVERY_ID"

(
  unset ROS_DISCOVERY_SERVER
  unset FASTDDS_DEFAULT_PROFILES_FILE
  unset FASTRTPS_DEFAULT_PROFILES_FILE
  export ROS_DOMAIN_ID="$ROS_DOMAIN_ID"
  export ROS_LOCALHOST_ONLY="$ROS_LOCALHOST_ONLY"
  export RMW_IMPLEMENTATION="$RMW_IMPLEMENTATION"
  exec fastdds discovery -i "$DISCOVERY_ID" -l "$DISCOVERY_HOST" -p "$DISCOVERY_PORT"
) &
DISCOVERY_PID="$!"

sleep 1
if ! kill -0 "$DISCOVERY_PID" 2>/dev/null; then
  echo "FastDDS discovery server failed to start." >&2
  wait "$DISCOVERY_PID" || true
  exit 1
fi

set +u
if [[ -f "$WORKSPACE_SETUP" ]]; then
  source "$WORKSPACE_SETUP"
else
  echo "Workspace setup not found, continuing without it: $WORKSPACE_SETUP" >&2
fi
set -u

echo "Starting DGX cmd_vel REST bridge"
echo "  host: $FLASK_HOST"
echo "  port: $FLASK_PORT"
echo "  topic: $CMD_VEL_TOPIC"
echo "  max linear_x: $MAX_LINEAR_X"
echo "  max angular_z: $MAX_ANGULAR_Z"
echo "  publish hz: $CMD_VEL_PUBLISH_HZ"
echo "  ros domain id: $ROS_DOMAIN_ID"
echo "  rmw: $RMW_IMPLEMENTATION"
echo "  discovery server: $ROS_DISCOVERY_SERVER"
echo "  fastdds profile: $FASTDDS_DEFAULT_PROFILES_FILE"
echo "  script: $BRIDGE_SCRIPT"

python3 "$BRIDGE_SCRIPT"
