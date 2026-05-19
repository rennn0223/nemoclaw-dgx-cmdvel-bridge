---
name: "cmd-vel-jetson-car"
description: "Control the physical Wheeltec/Jetson robot car through the DGX Spark REST bridge and ROS 2 /cmd_vel. Use when the user asks in Chinese or English to move the real car forward, back, left, right, stop, brake, halt, or drive for a number of seconds. Supports short iPhone voice commands such as 前進, 前進兩秒, 左轉, 右轉五秒, 後退, 停車."
---

# Wheeltec/Jetson Car Voice Control

Use this skill only for the physical robot car.

Control path:

```text
NemoClaw sandbox -> DGX REST bridge -> ROS 2 /cmd_vel -> Wheeltec/Jetson car
```

Use this helper script for all commands:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py <action> --seconds <N>
```

Actions:

```text
forward
slow-forward
back
left
right
stop
```

Do not call direct `POST /cmd_vel`. The helper uses `/command` and `/stop`.

## Safety

Stop always wins.

If the user says `停`, `停止`, `停車`, `煞車`, `不要動`, `stop`, `brake`, or `halt`, run immediately:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

For movement:

- If no duration is given, use `--seconds 1`.
- If duration is given, use that duration.
- If duration is longer than 5 seconds, ask for confirmation first.
- Keep first tests to 1 or 2 seconds.

## Voice Mapping

```text
前進 / 往前 / 走 / forward / go -> forward
慢慢前進 / 慢一點 / slow / slow forward -> slow-forward
後退 / 倒車 / 退後 / back / reverse -> back
左轉 / 往左 / 左邊 / left / turn left -> left
右轉 / 往右 / 右邊 / right / turn right -> right
停 / 停止 / 停車 / 煞車 / stop -> stop
```

Examples:

```text
前進 -> forward --seconds 1
前進兩秒 -> forward --seconds 2
慢慢前進 -> slow-forward --seconds 1
左轉一秒 -> left --seconds 1
右轉五秒 -> right --seconds 5
後退 -> back --seconds 1
停車 -> stop
```

Chinese numbers:

```text
一=1, 二=2, 兩=2, 三=3, 四=4, 五=5, 六=6, 七=7, 八=8, 九=9, 十=10
```

Ignore filler words such as `請`, `幫我`, `讓小車`, `車子`, `一下`, and `拜託`.

## Command Forms

Use exactly these command forms:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py slow-forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py back --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py left --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

The helper defaults to:

```text
ROBOT_BASE_URL=http://100.64.0.4:5000
```

## Response Style

Keep replies short.

```text
已前進 1 秒。
已右轉 5 秒。
已停車。
```

If a movement command fails, try stop once and briefly report the failure.
