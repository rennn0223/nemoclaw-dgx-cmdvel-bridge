---
name: "cmd-vel-jetson-car"
description: "Voice-friendly control for the physical Jetson Nano/Wheeltec robot car through the DGX Spark REST bridge and ROS 2 /cmd_vel. Use when the user asks in Chinese or English to move the real car forward, back, left, right, stop, brake, halt, or drive for a number of seconds. Trigger keywords: 小車, 車子, Jetson, Wheeltec, cmd_vel, 前進, 後退, 左轉, 右轉, 停車, 停止, 煞車, forward, back, left, right, stop."
---

# Voice Control For Jetson/Wheeltec Car

Use this skill for the physical robot car.

Command chain:

```text
NemoClaw sandbox -> DGX Spark REST bridge -> ROS 2 /cmd_vel -> Jetson/Wheeltec car
```

Current REST bridge:

```text
http://100.64.0.4:5000
```

The sandbox should use `POST /command` for movement and `POST /stop` for stop.
Do not use direct `POST /cmd_vel`; sandbox policy may block it.

## Safety First

Always prioritize stop.

If the user says any stop word, immediately run stop:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

Stop words:

```text
停
停止
停車
煞車
不要動
stop
brake
halt
```

For movement, always include a duration.

- If the user says a duration, use it.
- If the user does not say a duration, use `1` second.
- If the requested duration is longer than `5` seconds, ask for confirmation unless the user already clearly said it is safe.
- Prefer short tests: 1 to 2 seconds.

## Preferred Commands

Use the helper script:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py slow-forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py left --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py back --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

The helper defaults to:

```text
ROBOT_BASE_URL=http://100.64.0.4:5000
```

## iPhone Voice Phrases

Accept short voice commands. Map them directly:

```text
前進
往前
走
go
forward
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
```

```text
慢慢前進
慢一點
slow
slow forward
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py slow-forward --seconds 1
```

```text
後退
倒車
退後
back
reverse
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py back --seconds 1
```

```text
左轉
往左
左邊
left
turn left
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py left --seconds 1
```

```text
右轉
往右
右邊
right
turn right
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 1
```

## Duration Parsing

If the user says:

```text
右轉五秒
右轉 5 秒
right five seconds
turn right for 5 seconds
```

Run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 5
```

Other examples:

```text
前進兩秒 -> forward --seconds 2
左轉三秒 -> left --seconds 3
後退一秒 -> back --seconds 1
慢慢前進五秒 -> slow-forward --seconds 5
```

Chinese number mapping:

```text
一=1
二=2
兩=2
三=3
四=4
五=5
六=6
七=7
八=8
九=9
十=10
```

For voice input, tolerate filler words like:

```text
請
幫我
讓小車
車子
一下
拜託
```

## Motion Payloads

The helper sends these safe presets:

```text
forward       linear_x=0.10  angular_z=0.00
slow-forward  linear_x=0.08  angular_z=0.00
back          linear_x=-0.08 angular_z=0.00
left          linear_x=0.08  angular_z=0.40
right         linear_x=0.08  angular_z=-0.40
stop          POST /stop
```

ROS 2 Twist meaning:

```text
linear_x > 0   forward
linear_x < 0   reverse
angular_z > 0  left
angular_z < 0  right
```

## Response Style

Keep replies short for voice use.

Examples:

```text
已右轉 5 秒。
已前進 1 秒。
已停車。
```

If the command fails, send stop if possible and say briefly what failed.
