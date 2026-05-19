#!/usr/bin/env python3
"""REST bridge that publishes ROS 2 geometry_msgs/Twist commands to /cmd_vel.

Run this on the DGX Spark host after sourcing the correct ROS 2 environment.
"""

import os
import threading
import time

from flask import Flask, jsonify, request

import rclpy
from geometry_msgs.msg import Twist
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node


DEFAULT_TOPIC = os.getenv("CMD_VEL_TOPIC", "/cmd_vel")
MAX_LINEAR_X = float(os.getenv("MAX_LINEAR_X", "0.5"))
MAX_ANGULAR_Z = float(os.getenv("MAX_ANGULAR_Z", "1.0"))
PUBLISH_HZ = float(os.getenv("CMD_VEL_PUBLISH_HZ", "10"))

app = Flask(__name__)


def clamp(value, low, high):
    return max(low, min(high, value))


class CmdVelBridge(Node):
    def __init__(self):
        super().__init__("nemoclaw_cmd_vel_rest_bridge")
        self.publisher = self.create_publisher(Twist, DEFAULT_TOPIC, 10)
        self.lock = threading.Lock()
        self.linear_x = 0.0
        self.angular_z = 0.0
        self.until = 0.0
        self.timer = self.create_timer(1.0 / PUBLISH_HZ, self._publish_current)

    def set_command(self, linear_x, angular_z, seconds=0.0):
        linear_x = clamp(float(linear_x), -MAX_LINEAR_X, MAX_LINEAR_X)
        angular_z = clamp(float(angular_z), -MAX_ANGULAR_Z, MAX_ANGULAR_Z)
        seconds = max(0.0, float(seconds))

        with self.lock:
            self.linear_x = linear_x
            self.angular_z = angular_z
            self.until = time.monotonic() + seconds if seconds > 0.0 else 0.0

        self._publish(linear_x, angular_z)
        return {
            "topic": DEFAULT_TOPIC,
            "linear_x": linear_x,
            "angular_z": angular_z,
            "seconds": seconds,
        }

    def stop(self):
        with self.lock:
            self.linear_x = 0.0
            self.angular_z = 0.0
            self.until = 0.0
        self._publish(0.0, 0.0)

    def state(self):
        with self.lock:
            active = self.until == 0.0 or time.monotonic() < self.until
            return {
                "topic": DEFAULT_TOPIC,
                "linear_x": self.linear_x,
                "angular_z": self.angular_z,
                "active": active and (self.linear_x != 0.0 or self.angular_z != 0.0),
                "max_linear_x": MAX_LINEAR_X,
                "max_angular_z": MAX_ANGULAR_Z,
                "publish_hz": PUBLISH_HZ,
            }

    def _publish_current(self):
        should_publish = False
        with self.lock:
            if self.until > 0.0 and time.monotonic() >= self.until:
                self.linear_x = 0.0
                self.angular_z = 0.0
                self.until = 0.0
                should_publish = True
            linear_x = self.linear_x
            angular_z = self.angular_z

        if should_publish or linear_x != 0.0 or angular_z != 0.0:
            self._publish(linear_x, angular_z)

    def _publish(self, linear_x, angular_z):
        msg = Twist()
        msg.linear.x = float(linear_x)
        msg.angular.z = float(angular_z)
        self.publisher.publish(msg)


bridge = None


def spin_ros():
    try:
        rclpy.spin(bridge)
    except ExternalShutdownException:
        pass


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", **bridge.state()}), 200


@app.route("/cmd_vel", methods=["POST"])
def cmd_vel():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.get_json()
    linear_x = data.get("linear_x", data.get("x"))
    angular_z = data.get("angular_z", data.get("z", 0.0))
    seconds = data.get("seconds", 0.0)

    if linear_x is None:
        return jsonify({"error": "Missing 'linear_x'"}), 400

    command = bridge.set_command(linear_x, angular_z, seconds)
    return jsonify({"ok": True, "command": command}), 200


@app.route("/command", methods=["POST"])
def command_alias():
    return cmd_vel()


@app.route("/stop", methods=["POST"])
def stop():
    bridge.stop()
    return jsonify({"ok": True, "action": "stop", **bridge.state()}), 200


@app.route("/status", methods=["GET"])
def status():
    return jsonify(bridge.state()), 200


def main():
    global bridge
    rclpy.init()
    bridge = CmdVelBridge()
    ros_thread = threading.Thread(target=spin_ros, daemon=True)
    ros_thread.start()

    host = os.getenv("FLASK_HOST", "0.0.0.0")
    port = int(os.getenv("FLASK_PORT", "5000"))
    try:
        app.run(host=host, port=port, debug=False, use_reloader=False, threaded=True)
    finally:
        if rclpy.ok():
            bridge.stop()
            bridge.destroy_node()
            rclpy.shutdown()


if __name__ == "__main__":
    main()
