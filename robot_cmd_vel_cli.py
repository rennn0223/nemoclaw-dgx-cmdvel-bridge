#!/usr/bin/env python3
"""Safe CLI wrapper for a REST bridge that publishes ROS 2 /cmd_vel."""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request


DEFAULT_BASE_URL = os.getenv("ROBOT_BASE_URL", "http://192.168.50.48:5000")
MAX_ABS_LINEAR_X = float(os.getenv("MAX_ABS_LINEAR_X", "0.5"))
MAX_ABS_ANGULAR_Z = float(os.getenv("MAX_ABS_ANGULAR_Z", "1.0"))


class RobotError(RuntimeError):
    pass


def clamp(value, low, high):
    return max(low, min(high, value))


def request_json(method, base_url, path, payload=None, timeout=10.0):
    data = None
    headers = {"Accept": "application/json"}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(
        f"{base_url.rstrip('/')}{path}",
        data=data,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RobotError(f"HTTP {e.code} {path}: {body}") from e
    except urllib.error.URLError as e:
        raise RobotError(f"Failed to reach robot bridge at {base_url}: {e}") from e
    except TimeoutError as e:
        raise RobotError(f"Timed out calling {path}") from e


def get_json(base_url, path, timeout=10.0):
    return request_json("GET", base_url, path, timeout=timeout)


def post_json(base_url, path, payload=None, timeout=10.0):
    return request_json("POST", base_url, path, payload or {}, timeout=timeout)


def print_json(obj):
    print(json.dumps(obj, indent=2, sort_keys=True))


def command_health(args):
    print_json(get_json(args.base_url, "/health"))


def command_status(args):
    print_json(get_json(args.base_url, "/status"))


def command_stop(args):
    result = post_json(args.base_url, "/stop")
    print_json({"ok": True, "action": "stop", "result": result})


def command_drive(args):
    linear_x = clamp(args.linear_x, -MAX_ABS_LINEAR_X, MAX_ABS_LINEAR_X)
    angular_z = clamp(args.angular_z, -MAX_ABS_ANGULAR_Z, MAX_ABS_ANGULAR_Z)
    seconds = max(0.0, args.seconds)
    payload = {"linear_x": linear_x, "angular_z": angular_z, "seconds": seconds}

    result = None
    try:
        result = post_json(args.base_url, "/cmd_vel", payload)
        if seconds > 0:
            time.sleep(seconds)
    finally:
        stop_result = post_json(args.base_url, "/stop")

    print_json(
        {
            "ok": True,
            "action": "drive",
            "linear_x": linear_x,
            "angular_z": angular_z,
            "seconds": seconds,
            "command_result": result,
            "stop_result": stop_result,
        }
    )


def command_say(args):
    text = " ".join(args.text).lower()
    linear_x = 0.0
    angular_z = 0.0
    seconds = args.seconds

    if any(word in text for word in ["stop", "brake", "halt", "停", "停止", "煞車"]):
        command_stop(args)
        return
    if any(word in text for word in ["back", "reverse", "退", "後退", "倒車"]):
        linear_x = -0.2
    elif any(word in text for word in ["forward", "ahead", "前", "前進", "直走"]):
        linear_x = 0.3
    if any(word in text for word in ["left", "左"]):
        angular_z = 0.5
        if linear_x == 0.0:
            linear_x = 0.2
    if any(word in text for word in ["right", "右"]):
        angular_z = -0.5
        if linear_x == 0.0:
            linear_x = 0.2
    if any(word in text for word in ["slow", "慢"]):
        linear_x *= 0.6
        angular_z *= 0.7

    if linear_x == 0.0 and angular_z == 0.0:
        raise RobotError(f"Could not map natural language to cmd_vel: {' '.join(args.text)}")

    args.linear_x = linear_x
    args.angular_z = angular_z
    command_drive(args)


def build_parser():
    parser = argparse.ArgumentParser(description="Safe /cmd_vel robot CLI")
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"REST bridge base URL, default: {DEFAULT_BASE_URL}",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    health = sub.add_parser("health", help="Check REST bridge health")
    health.set_defaults(func=command_health)

    status = sub.add_parser("status", help="Get bridge status")
    status.set_defaults(func=command_status)

    stop = sub.add_parser("stop", help="Publish zero cmd_vel")
    stop.set_defaults(func=command_stop)

    drive = sub.add_parser("drive", help="Publish cmd_vel briefly, then stop")
    drive.add_argument("--linear-x", type=float, required=True)
    drive.add_argument("--angular-z", type=float, default=0.0)
    drive.add_argument("--seconds", type=float, default=1.0)
    drive.set_defaults(func=command_drive)

    say = sub.add_parser("say", help="Map simple natural language to cmd_vel")
    say.add_argument("text", nargs="+")
    say.add_argument("--seconds", type=float, default=2.0)
    say.set_defaults(func=command_say)

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        args.func(args)
        return 0
    except KeyboardInterrupt:
        try:
            post_json(args.base_url, "/stop")
        finally:
            print("Interrupted; stop command sent.", file=sys.stderr)
        return 130
    except RobotError as e:
        try:
            post_json(args.base_url, "/stop")
        except Exception:
            pass
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
