# Voice Mapping Reference

Use this reference when interpreting short iPhone voice commands.

## Action Mapping

```text
前進 / 往前 / 走 / forward / go -> forward
慢慢前進 / 慢一點 / slow / slow forward -> slow-forward
後退 / 倒車 / 退後 / back / reverse -> back
左轉 / 往左 / 左邊 / left / turn left -> left
右轉 / 往右 / 右邊 / right / turn right -> right
停 / 停止 / 停車 / 煞車 / 不要動 / stop / brake / halt -> stop
```

## Examples

```text
前進 -> forward --seconds 1
前進兩秒 -> forward --seconds 2
慢慢前進 -> slow-forward --seconds 1
左轉一秒 -> left --seconds 1
右轉五秒 -> right --seconds 5
後退 -> back --seconds 1
停車 -> stop
```

## Chinese Numbers

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

## Filler Words

Ignore filler words:

```text
請
幫我
讓小車
車子
一下
拜託
```

## Command Forms

Use exactly these forms after choosing the action and duration:

```bash
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py slow-forward --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py back --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py left --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py right --seconds 1
python3 /sandbox/.openclaw/skills/cmd-vel-jetson-car/scripts/car_cmd.py stop
```
