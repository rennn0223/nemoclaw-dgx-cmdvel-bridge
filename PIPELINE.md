# DGX Spark + NemoClaw + Jetson Nano /cmd_vel Pipeline

This is the working pipeline for controlling physical Jetson Nano robot cars with natural language through NemoClaw.

The goal is simple:

```text
NemoClaw hears a request like "move forward"
-> sandbox sends REST to DGX Spark
-> DGX publishes ROS 2 /cmd_vel
-> one or more Jetson Nano cars move
```

## 1. What Runs Where

```text
MacBook Pro
  Used to SSH into DGX Spark and manage the setup.

NemoClaw sandbox
  Runs the skill and helper scripts.
  Sends HTTP requests to DGX Spark.

DGX Spark
  Runs dgx_cmd_vel_rest_api.py.
  Receives REST commands.
  Publishes ROS 2 geometry_msgs/msg/Twist on /cmd_vel.

Jetson Nano car(s)
  Subscribe to /cmd_vel.
  Convert Twist commands to motor movement.
```

Known addresses:

```text
DGX REST URL on Tailscale:      http://100.64.0.4:5000
DGX FastDDS discovery server:   100.64.0.4:11811
Jetson Nano car on robot LAN:   192.168.50.29
```

Current verified state:

- LAN REST access works.
- Tailscale REST access works.
- `GET /health` works.
- `POST /stop` works.
- `POST /command` works.
- Sandbox blocks direct `POST /cmd_vel`, so movement must use `/command`.
- Two cars can subscribe to the same `/cmd_vel` and move forward together.
- Movement has two stop layers: the DGX bridge publishes zero Twist when duration expires, and the sandbox helper sends `/stop` after the requested seconds.

There are two networking modes. See [MODES.md](MODES.md) for the short version.

- Same Wi-Fi/LAN: use `auto_lan.sh` on DGX and `wheeltec_bringup_lan.sh` on each car.
- Different networks/Tailscale: use `auto_tailscale.sh` on DGX and `wheeltec_bringup_tailscale.sh` on each car.

## 2. Files In This Package

```text
dgx_cmd_vel_rest_api.py
  DGX host REST bridge. Publishes ROS 2 /cmd_vel.

auto.sh
  DGX Jazzy host startup script. Sources ROS 2, sets FastDDS discovery, and starts the REST bridge.

auto_lan.sh
  DGX same-Wi-Fi launcher. Uses normal ROS 2 LAN discovery.

auto_tailscale.sh
  DGX cross-network launcher. Starts FastDDS discovery over Tailscale, then the REST bridge.

start_dgx_cmd_vel_pipeline.sh
  One-command DGX launcher. Starts FastDDS discovery in the background, then starts the REST bridge.

fastdds_super_tailscale.xml
  FastDDS SUPER_CLIENT profile for DGX bridge and Jetson clients.

fastdds_tailscale.xml
  Tailscale UDP transport profile.

wheeltec_bringup_tailscale.sh
  Jetson/Wheeltec launcher. Sources Humble, sets FastDDS SUPER_CLIENT, and launches robot bringup.

wheeltec_ros_tailscale_shell.sh
  Jetson/Wheeltec inspection shell with the same ROS/FastDDS environment.

wheeltec_bringup_lan.sh
  Jetson/Wheeltec same-Wi-Fi bringup launcher.

wheeltec_ros_lan_shell.sh
  Jetson/Wheeltec same-Wi-Fi inspection shell.

run_dgx_cmd_vel_bridge.sh
  Generic host startup script with the same defaults as auto.sh.

robot_cmd_vel_cli.py
  Client CLI for health, stop, and command tests.

nemoclaw-cmd-vel-jetson/SKILL.md
  NemoClaw skill instructions.

nemoclaw-cmd-vel-jetson/scripts/car_cmd.py
  Small helper used by the skill.
```

## 3. Start The DGX Host Bridge

Copy these files to one folder on DGX Spark:

```text
dgx_cmd_vel_rest_api.py
auto.sh
start_dgx_cmd_vel_pipeline.sh
fastdds_super_tailscale.xml
fastdds_tailscale.xml
```

Recommended one-command startup:

```bash
chmod +x start_dgx_cmd_vel_pipeline.sh
./start_dgx_cmd_vel_pipeline.sh
```

This starts both:

```text
FastDDS discovery server: 100.64.0.4:11811
REST bridge:              0.0.0.0:5000
```

For debugging, you can still run the two pieces separately.

Terminal 1, start the FastDDS discovery server:

```bash
source /opt/ros/jazzy/setup.bash

unset ROS_DISCOVERY_SERVER
unset FASTDDS_DEFAULT_PROFILES_FILE
unset FASTRTPS_DEFAULT_PROFILES_FILE

export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

fastdds discovery -i 0 -l 100.64.0.4 -p 11811
```

Keep that terminal running.

Terminal 2, start only the REST bridge:

```bash
chmod +x auto.sh
./auto.sh
```

The script does this for you:

```bash
source /opt/ros/jazzy/setup.bash
source ~/IsaacSim-ros_workspaces/jazzy_ws/install/setup.bash
export FLASK_HOST=0.0.0.0
export FLASK_PORT=5000
export CMD_VEL_TOPIC=/cmd_vel
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export ROS_DISCOVERY_SERVER=100.64.0.4:11811
export FASTDDS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
export FASTRTPS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
python3 dgx_cmd_vel_rest_api.py
```

Optional host settings:

```bash
export CMD_VEL_TOPIC=/cmd_vel
export FLASK_HOST=0.0.0.0
export FLASK_PORT=5000
export MAX_LINEAR_X=1.0
export MAX_ANGULAR_Z=1.0
export CMD_VEL_PUBLISH_HZ=10
./auto.sh
```

`auto.sh` sets the REST bridge and ROS discovery environment:

```bash
export FLASK_HOST=0.0.0.0
export FLASK_PORT=5000
export CMD_VEL_TOPIC=/cmd_vel
export MAX_LINEAR_X=1.0
export MAX_ANGULAR_Z=1.0
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export ROS_DISCOVERY_SERVER=100.64.0.4:11811
export FASTDDS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
export FASTRTPS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
```

After starting the bridge, verify the Python process has the ROS discovery variables:

```bash
ps eww $(pgrep -f dgx_cmd_vel_rest_api.py) | tr ' ' '\n' | \
  grep -E 'ROS_DISCOVERY_SERVER|RMW_IMPLEMENTATION|ROS_DOMAIN_ID|ROS_LOCALHOST_ONLY|FASTDDS|FASTRTPS'
```

Expected important line:

```text
ROS_DISCOVERY_SERVER=100.64.0.4:11811
```

If your ROS workspace setup file is somewhere else:

```bash
export WORKSPACE_SETUP=/path/to/install/setup.bash
./auto.sh
```

## 4. Confirm DGX Can Reach The Cars

Copy the Jetson files to the car:

```bash
scp wheeltec_bringup_tailscale.sh wheeltec_ros_tailscale_shell.sh fastdds_super_tailscale.xml \
  wheeltec@<JETSON_IP>:/home/wheeltec/
```

Terminal 1 on the Jetson, start bringup:

```bash
cd /home/wheeltec
chmod +x wheeltec_bringup_tailscale.sh wheeltec_ros_tailscale_shell.sh
./wheeltec_bringup_tailscale.sh
```

Terminal 2 on the Jetson, open an inspection shell:

```bash
cd /home/wheeltec
./wheeltec_ros_tailscale_shell.sh
```

Then run:

```bash
ros2 topic list -t --no-daemon
ros2 topic echo /odom nav_msgs/msg/Odometry --once
ros2 topic hz /odom
ros2 topic echo /imu/data_raw sensor_msgs/msg/Imu --once
ros2 topic hz /imu/data_raw
ros2 topic echo /cmd_vel geometry_msgs/msg/Twist --no-daemon
```

On DGX, check the Jetson network:

```bash
ping 192.168.50.29
```

Check ROS 2 can see `/cmd_vel`:

```bash
ros2 topic info /cmd_vel
```

Optional: watch incoming commands on a Jetson:

```bash
ros2 topic echo /cmd_vel
```

If you have two cars moving together, both cars should be on the same ROS 2 network/domain and both should subscribe to `/cmd_vel`.

## 5. Test REST Without Moving

From sandbox, MacBook, or another trusted Tailscale device:

```bash
curl http://100.64.0.4:5000/health
```

Expected result includes:

```json
{"status":"ok","topic":"/cmd_vel"}
```

Test stop:

```bash
curl -X POST http://100.64.0.4:5000/stop
```

Test command path without movement:

```bash
curl -X POST http://100.64.0.4:5000/command \
  -H "Content-Type: application/json" \
  -d '{"linear_x":0.0,"angular_z":0.0,"seconds":1}'
```

## 6. First Safe Movement Test

Only do this when the cars are physically safe to move.

Forward for 1 second:

```bash
curl -X POST http://100.64.0.4:5000/command \
  -H "Content-Type: application/json" \
  -d '{"linear_x":0.1,"angular_z":0.0,"seconds":1}'
```

Emergency stop:

```bash
curl -X POST http://100.64.0.4:5000/stop
```

Expected behavior:

- During motion, `/cmd_vel` publishes the requested Twist.
- When `seconds` expires, the DGX bridge publishes zero Twist.
- When using `car_cmd.py`, the helper also sends `POST /stop` after sleeping for the requested seconds.

If the car keeps moving, immediately run:

```bash
curl -X POST http://100.64.0.4:5000/stop
```

Then check that DGX is running the updated `dgx_cmd_vel_rest_api.py`.

## 6.1 Update And Restart After Code Changes

Copy updated host files to DGX:

```bash
scp dgx_cmd_vel_rest_api.py start_dgx_cmd_vel_pipeline.sh auto.sh \
  nvidia@100.64.0.4:/home/nvidia/
```

Copy updated skill/helper to sandbox:

```bash
openshell sandbox upload my-assistant nemoclaw-cmd-vel-jetson \
  /sandbox/.openclaw/skills/cmd-vel-jetson-car
```

On DGX, stop old processes:

```bash
pkill -f dgx_cmd_vel_rest_api.py || true
pkill -f "fastdds discovery" || true
```

Start the full DGX pipeline:

```bash
cd /home/nvidia
chmod +x auto.sh start_dgx_cmd_vel_pipeline.sh
./auto.sh
```

In another terminal, verify:

```bash
curl http://100.64.0.4:5000/health
```

In sandbox, test stop first:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

Then test a short motion:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
```

The command output should include both `command` and `stop` results.

## 7. Install The NemoClaw Skill

Upload the skill folder to sandbox:

```bash
openshell sandbox upload my-assistant nemoclaw-cmd-vel-jetson \
  /sandbox/.openclaw/skills/cmd-vel-jetson-car
```

Update the skill the same way whenever `SKILL.md` or `scripts/car_cmd.py` changes:

```bash
openshell sandbox upload my-assistant nemoclaw-cmd-vel-jetson \
  /sandbox/.openclaw/skills/cmd-vel-jetson-car
```

The current skill is optimized for iPhone voice input. Short commands work best:

```text
前進
右轉五秒
左轉兩秒
慢慢前進
停車
```

The skill tells NemoClaw:

- Use DGX REST, not direct ROS 2.
- Use `/command` for movement.
- Use `/stop` for stop.
- Avoid direct `POST /cmd_vel` because sandbox policy can deny it.
- Keep movement short by default.

## 8. Use The Helper Script

For local LAN control:

```bash
export ROBOT_BASE_URL=http://192.168.50.48:5000
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

For Tailscale control:

```bash
export ROBOT_BASE_URL=http://100.64.0.4:5000
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

Available helper actions:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py slow-forward
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py left
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py back
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

## 9. Natural Language Mapping

The skill maps simple requests to these payloads:

```text
"forward" or "前進"
  {"linear_x":0.1,"angular_z":0.0,"seconds":1}

"slow forward" or "慢慢前進"
  {"linear_x":0.08,"angular_z":0.0,"seconds":1}

"left" or "左轉"
  {"linear_x":0.08,"angular_z":0.4,"seconds":1}

"right" or "右轉"
  {"linear_x":0.08,"angular_z":-0.4,"seconds":1}

"back" or "後退"
  {"linear_x":-0.08,"angular_z":0.0,"seconds":1}

"stop" or "停止"
  POST /stop
```

ROS 2 Twist meaning:

```text
linear_x > 0   forward
linear_x < 0   reverse
angular_z > 0  left
angular_z < 0  right
```

## 10. Tailscale Notes

Use Tailscale as the remote access boundary:

```text
remote client or sandbox
  -> http://100.64.0.4:5000
  -> DGX Spark REST bridge
  -> local ROS 2 /cmd_vel
  -> Jetson Nano car(s)
```

Do not expose port `5000` to the public internet.

Make sure sandbox policy allows:

```text
GET  http://100.64.0.4:5000/health
POST http://100.64.0.4:5000/command
POST http://100.64.0.4:5000/stop
```

The direct `/cmd_vel` REST path is not needed from sandbox.

## 11. Troubleshooting

If `curl http://100.64.0.4:5000/health` returns `policy_denied`:

- Sandbox egress policy has not allowed the Tailscale URL yet.

If `curl http://100.64.0.4:5000/health` times out:

- DGX bridge may not be running.
- Tailscale may not be connected.
- DGX firewall may block port `5000`.

If health works but cars do not move:

- Check `ros2 topic info /cmd_vel` on DGX.
- Check `ros2 topic echo /cmd_vel` on Jetson.
- Check Jetson motor node is running.
- Check car battery and motor driver power.

If only one car moves:

- Check the other car is on the same ROS 2 domain.
- Check the other car subscribes to `/cmd_vel`.
- Check its motor controller and power.

If movement works but does not stop:

- Send `POST /stop`.
- Restart the DGX bridge if needed.
- Add a shorter `seconds` value for future tests.

## 12. Daily Run Checklist

1. Power on DGX Spark and Jetson car(s).
2. Confirm cars are safe to move.
3. Start the DGX bridge:

```bash
./auto.sh
```

4. Test health:

```bash
curl http://100.64.0.4:5000/health
```

5. Test stop:

```bash
curl -X POST http://100.64.0.4:5000/stop
```

6. Send a short forward test:

```bash
curl -X POST http://100.64.0.4:5000/command \
  -H "Content-Type: application/json" \
  -d '{"linear_x":0.1,"angular_z":0.0,"seconds":1}'
```

7. Use NemoClaw natural language control.
