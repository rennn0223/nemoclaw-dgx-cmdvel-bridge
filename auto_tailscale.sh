#!/usr/bin/env bash
set -euo pipefail

# DGX Spark Tailscale launcher.
# Use this when DGX and cars are not on the same LAN, or when you want all ROS 2
# discovery traffic to go through Tailscale + FastDDS discovery server.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

exec "$SCRIPT_DIR/start_dgx_cmd_vel_pipeline.sh"
