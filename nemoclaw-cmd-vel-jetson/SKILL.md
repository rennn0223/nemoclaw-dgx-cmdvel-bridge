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

Always control the car through the helper script:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py <action> --seconds <N>
```

Supported actions are defined in `scripts/car_cmd.py`:

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

If the user says `停`, `停止`, `停車`, `煞車`, `不要動`, `stop`, `brake`, or `halt`, immediately run:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

For movement:

- If no duration is given, use `--seconds 1`.
- If duration is given, use that duration.
- If duration is longer than 5 seconds, ask for confirmation first.
- Keep first tests to 1 or 2 seconds.

## Voice Mapping

For Chinese/English command mapping, number parsing, and examples, read:

```text
references/voice_mapping.md
```

Use the mapping there to choose one action and one duration.

## Failure Handling

If a command fails:

```text
HTTP 403 / policy_denied -> tell the user the sandbox policy blocked the REST call.
Timeout / connection refused -> tell the user the DGX REST bridge may be down.
No movement but command succeeds -> ask the user to check /cmd_vel echo, robot power, safety flags, or motor node.
```

After any movement failure, try stop once:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```

## Response Style

Keep replies short.

```text
已前進 1 秒。
已右轉 5 秒。
已停車。
```

If a movement command fails, briefly report the likely cause.
