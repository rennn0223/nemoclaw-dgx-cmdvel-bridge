# Two ROS 2 Networking Modes

This project supports two ways to connect DGX Spark to Wheeltec/Jetson cars.

## Mode A: Same Wi-Fi / Same LAN

Use this when DGX and the cars are on the same Wi-Fi/LAN and DGX can already see car topics with:

```bash
ros2 topic list -t
```

In this mode, do not use `ROS_DISCOVERY_SERVER` and do not use the Tailscale FastDDS XML profile.

### DGX

```bash
cd /home/nvidia
pkill -f dgx_cmd_vel_rest_api.py || true
pkill -f "fastdds discovery" || true
chmod +x auto_lan.sh
./auto_lan.sh
```

### Jetson/Wheeltec

Terminal 1:

```bash
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

Expected from DGX:

```text
Publisher count: 1
Subscription count: 1
```

With two cars, expect:

```text
Subscription count: 2
```

## Mode B: Different Networks / Tailscale

Use this when DGX and the cars are not on the same LAN, or when you want ROS 2 discovery traffic through Tailscale.

This mode uses:

```text
DGX Tailscale IP: 100.64.0.4
FastDDS discovery server: 100.64.0.4:11811
FastDDS SUPER_CLIENT XML: ~/fastdds_super_tailscale.xml
```

### DGX

```bash
cd /home/nvidia
pkill -f dgx_cmd_vel_rest_api.py || true
pkill -f "fastdds discovery" || true
chmod +x auto_tailscale.sh start_dgx_cmd_vel_pipeline.sh
./auto_tailscale.sh
```

### Jetson/Wheeltec

Terminal 1:

```bash
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

## REST Control Is The Same In Both Modes

Sandbox/NemoClaw always calls the DGX REST bridge:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

The REST bridge then publishes `/cmd_vel` into whichever ROS 2 graph the DGX launcher selected.

## Quick Decision

Use LAN mode if:

```text
DGX and cars are on the same Wi-Fi, and ros2 topic list shows car topics.
```

Use Tailscale mode if:

```text
DGX and cars are on different networks, or LAN multicast discovery does not work.
```
