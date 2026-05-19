# NemoClaw DGX Spark ROS 2 /cmd_vel Bridge

Control physical Wheeltec/Jetson robot cars with NemoClaw natural language commands through a DGX Spark REST bridge.

Project page:

```text
https://rennn0223.github.io/nemoclaw-dgx-cmdvel-bridge/
```

```text
NemoClaw / sandbox
  -> HTTP REST /command or /stop
  -> DGX Spark
  -> ROS 2 /cmd_vel
  -> Wheeltec / Jetson car(s)
```

This repository supports two ROS 2 networking modes:

- **Same Wi-Fi / LAN**: normal ROS 2 discovery.
- **Different networks / Tailscale**: FastDDS discovery server through Tailscale.

See [MODES.md](MODES.md) for the short mode comparison and [PIPELINE.md](PIPELINE.md) for the full working notes.

## Safety

The robot moves physically.

- Test `stop` first.
- Start with `--seconds 1`.
- Keep the robot lifted or in a clear area for first tests.
- Do not expose the REST bridge to the public internet.
- Use Tailscale or a trusted private network.

The bridge has two stop layers:

- `dgx_cmd_vel_rest_api.py` publishes zero Twist when the requested duration expires.
- `car_cmd.py` sends `/stop` after the requested duration.

## Files

DGX Spark:

```text
dgx_cmd_vel_rest_api.py
auto_lan.sh
auto_tailscale.sh
start_dgx_cmd_vel_pipeline.sh
fastdds_super_tailscale.xml
fastdds_tailscale.xml
```

Jetson/Wheeltec:

```text
wheeltec_bringup_lan.sh
wheeltec_ros_lan_shell.sh
wheeltec_bringup_tailscale.sh
wheeltec_ros_tailscale_shell.sh
fastdds_super_tailscale.xml
```

NemoClaw sandbox skill:

```text
nemoclaw-cmd-vel-jetson/
```

## Quick Install From GitHub

These commands install the launcher files from this repository.

DGX Spark:

```bash
curl -fsSL https://raw.githubusercontent.com/rennn0223/nemoclaw-dgx-cmdvel-bridge/main/install.sh | \
  ROLE=dgx GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge bash
```

Jetson/Wheeltec:

```bash
curl -fsSL https://raw.githubusercontent.com/rennn0223/nemoclaw-dgx-cmdvel-bridge/main/install.sh | \
  ROLE=jetson GITHUB_REPO=rennn0223/nemoclaw-dgx-cmdvel-bridge bash
```

Manual install is also fine:

```bash
git clone https://github.com/rennn0223/nemoclaw-dgx-cmdvel-bridge.git
cd nemoclaw-dgx-cmdvel-bridge
ROLE=dgx ./install.sh
```

## Mode A: Same Wi-Fi / LAN

Use this when DGX and the cars are on the same Wi-Fi/LAN and DGX can already see car topics:

```bash
ros2 topic list -t
```

### DGX

```bash
ssh nvidia@<DGX_IP_OR_TAILSCALE_IP>
cd /home/nvidia
pkill -f dgx_cmd_vel_rest_api.py || true
pkill -f "fastdds discovery" || true
chmod +x auto_lan.sh
./auto_lan.sh
```

### Jetson/Wheeltec

Terminal 1:

```bash
ssh wheeltec@<JETSON_IP>
cd /home/wheeltec
chmod +x wheeltec_bringup_lan.sh wheeltec_ros_lan_shell.sh
./wheeltec_bringup_lan.sh
```

Terminal 2:

```bash
cd /home/wheeltec
./wheeltec_ros_lan_shell.sh
ros2 topic info /cmd_vel -v
```

Expected with one car:

```text
Publisher count: 1
Subscription count: 1
```

Expected with two cars:

```text
Publisher count: 1
Subscription count: 2
```

## Mode B: Different Networks / Tailscale

Use this when DGX and the cars are on different networks, or when LAN multicast discovery does not work.

Default Tailscale/FastDDS settings:

```text
DGX Tailscale IP:            100.64.0.4
FastDDS discovery server:    100.64.0.4:11811
DGX REST bridge:             http://100.64.0.4:5000
```

If your DGX Tailscale IP is different, edit:

```text
auto_tailscale.sh
start_dgx_cmd_vel_pipeline.sh
fastdds_super_tailscale.xml
fastdds_tailscale.xml
nemoclaw-cmd-vel-jetson/scripts/car_cmd.py
```

### DGX

```bash
ssh nvidia@100.64.0.4
cd /home/nvidia
pkill -f dgx_cmd_vel_rest_api.py || true
pkill -f "fastdds discovery" || true
chmod +x auto_tailscale.sh start_dgx_cmd_vel_pipeline.sh
./auto_tailscale.sh
```

### Jetson/Wheeltec

Terminal 1:

```bash
ssh wheeltec@<JETSON_IP>
cd /home/wheeltec
chmod +x wheeltec_bringup_tailscale.sh wheeltec_ros_tailscale_shell.sh
./wheeltec_bringup_tailscale.sh
```

Terminal 2:

```bash
cd /home/wheeltec
./wheeltec_ros_tailscale_shell.sh
ros2 topic info /cmd_vel -v --no-daemon
```

## Install The NemoClaw Skill

On DGX, place or clone the skill folder at:

```text
/home/nvidia/cmd-vel-jetson-car
```

Then install it into the sandbox:

```bash
nemoclaw my-assistant skill install /home/nvidia/cmd-vel-jetson-car
```

If you are not using the NemoClaw skill installer, you can manually upload the folder as a fallback:

```bash
openshell sandbox upload my-assistant cmd-vel-jetson-car \
  /sandbox/.openclaw/skills/cmd-vel-jetson-car
```

The skill is optimized for short iPhone voice input:

```text
前進
前進兩秒
慢慢前進
左轉一秒
右轉五秒
後退
停車
```

## Test Commands

Health:

```bash
curl http://100.64.0.4:5000/health
```

Stop:

```bash
curl -X POST http://100.64.0.4:5000/stop
```

Move forward for one second:

```bash
curl -X POST http://100.64.0.4:5000/command \
  -H "Content-Type: application/json" \
  -d '{"linear_x":0.1,"angular_z":0.0,"seconds":1}'
```

Sandbox helper:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 1
```

## Troubleshooting

Check `/cmd_vel` publishers and subscribers:

```bash
ros2 topic info /cmd_vel -v
```

Interpretation:

```text
Publisher count: 0, Subscription count: 1
  Car is listening, but DGX bridge is not publishing in this ROS graph.

Publisher count: 1, Subscription count: 0
  DGX bridge is publishing, but cars are not subscribed in this ROS graph.

Publisher count: 1, Subscription count: 1 or more
  ROS graph is connected. If the car still does not move, check car power, safety flags, motor node, or emergency stop.
```

If using LAN mode, make sure these are unset:

```bash
unset ROS_DISCOVERY_SERVER
unset FASTDDS_DEFAULT_PROFILES_FILE
unset FASTRTPS_DEFAULT_PROFILES_FILE
```

If using Tailscale mode, make sure these are set:

```bash
export ROS_DISCOVERY_SERVER=100.64.0.4:11811
export FASTDDS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
export FASTRTPS_DEFAULT_PROFILES_FILE=$HOME/fastdds_super_tailscale.xml
```
