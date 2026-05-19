# DGX Spark nemoclaw to ROS 2 /cmd_vel

This version is for the physical robot that listens to `/cmd_vel`.

For the current end-to-end workflow, two-car setup, NemoClaw skill, and future Tailscale access plan, see [PIPELINE.md](PIPELINE.md).

The Isaac Sim bridge you showed forwards `/command` to Isaac Sim `/cmd` using `speed` and `steering_angle`. For the real robot, use `geometry_msgs/msg/Twist` instead:

- `linear.x > 0`: forward
- `linear.x < 0`: reverse
- `angular.z > 0`: turn left
- `angular.z < 0`: turn right
- both zero: stop

## DGX Spark side

On the DGX Spark, source your ROS 2 environment first:

```bash
source /opt/ros/humble/setup.bash
source ~/IsaacSim-ros_workspaces/install/setup.bash
```

Then start the REST bridge:

```bash
./run_dgx_cmd_vel_bridge.sh
```

Optional environment variables:

```bash
export CMD_VEL_TOPIC=/cmd_vel
export FLASK_HOST=0.0.0.0
export FLASK_PORT=5000
export MAX_LINEAR_X=0.5
export MAX_ANGULAR_Z=1.0
```

## Client / nemoclaw side

Health check:

```bash
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 health
```

Remote Tailscale URL:

```bash
python3 robot_cmd_vel_cli.py --base-url http://100.64.0.4:5000 health
```

Move forward for 2 seconds, then stop:

```bash
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 drive --linear-x 0.25 --angular-z 0.0 --seconds 2
```

Turn left while moving slowly for 2 seconds, then stop:

```bash
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 drive --linear-x 0.2 --angular-z 0.5 --seconds 2
```

Stop:

```bash
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 stop
```

Simple natural language mapping:

```bash
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 say "慢慢前進" --seconds 2
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 say "向左轉" --seconds 2
python3 robot_cmd_vel_cli.py --base-url http://192.168.50.48:5000 say "停止"
```

## Direct REST examples

```bash
curl -X POST http://192.168.50.48:5000/cmd_vel \
  -H "Content-Type: application/json" \
  -d '{"linear_x": 0.25, "angular_z": 0.0, "seconds": 2}'
```

```bash
curl -X POST http://192.168.50.48:5000/stop
```

## Check ROS 2 receives it

On the robot or DGX ROS 2 environment:

```bash
ros2 topic echo /cmd_vel
```

You should see `geometry_msgs/msg/Twist` messages with `linear.x` and `angular.z`.

## About `cmd_to_vel`

Use `cmd_to_vel` only in the Isaac Sim path if you need to convert a `/cmd_vel` style command into the Ackermann command expected by the simulated Leatherback stack.

For the physical robot that already listens to `/cmd_vel`, publish `/cmd_vel` directly. Do not send the old Isaac Sim REST payload:

```json
{"speed": 0.3, "steering_angle": 0.2}
```

Use this instead:

```json
{"linear_x": 0.3, "angular_z": 0.2, "seconds": 2}
```
