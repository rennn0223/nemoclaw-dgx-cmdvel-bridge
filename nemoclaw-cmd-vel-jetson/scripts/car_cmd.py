#!/usr/bin/env python3
"""Send safe robot car commands through the DGX Spark REST bridge."""

import argparse
import json
import os
import time
import urllib.error
import urllib.request


DEFAULT_BASE_URL = os.getenv("ROBOT_BASE_URL", "http://100.64.0.4:5000")


PRESETS = {
    "forward": {"linear_x": 0.1, "angular_z": 0.0, "seconds": 1.0},
    "slow-forward": {"linear_x": 0.08, "angular_z": 0.0, "seconds": 1.0},
    "back": {"linear_x": -0.08, "angular_z": 0.0, "seconds": 1.0},
    "left": {"linear_x": 0.08, "angular_z": 0.4, "seconds": 1.0},
    "right": {"linear_x": 0.08, "angular_z": -0.4, "seconds": 1.0},
}


def post(base_url, path, payload):
    req = urllib.request.Request(
        base_url.rstrip("/") + path,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body) if body else {}


def main():
    parser = argparse.ArgumentParser(description="Control Jetson Nano car through DGX REST bridge")
    parser.add_argument("action", choices=["forward", "slow-forward", "back", "left", "right", "stop"])
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--seconds", type=float)
    args = parser.parse_args()

    if args.action == "stop":
        print(json.dumps(post(args.base_url, "/stop", {}), indent=2, sort_keys=True))
        return

    payload = dict(PRESETS[args.action])
    if args.seconds is not None:
        payload["seconds"] = max(0.0, args.seconds)
    command_result = None
    stop_result = None
    try:
        command_result = post(args.base_url, "/command", payload)
        seconds = float(payload.get("seconds", 0.0))
        if seconds > 0.0:
            time.sleep(seconds)
    finally:
        try:
            stop_result = post(args.base_url, "/stop", {})
        except urllib.error.URLError as exc:
            stop_result = {"error": str(exc)}

    print(
        json.dumps(
            {
                "ok": True,
                "action": args.action,
                "command": command_result,
                "stop": stop_result,
            },
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
