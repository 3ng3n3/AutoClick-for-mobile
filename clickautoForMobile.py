
import subprocess
import threading
import time
import math
from collections import deque

DEVICE = "/dev/input/event2"

SCREEN_W = 720
SCREEN_H = 1600

EXTRA_CPS = 30
CLICK_INTERVAL = 1 / EXTRA_CPS

TRIGGER_CLICKS = 2
TRIGGER_WINDOW = 0.20
ACTIVE_TIMEOUT = 0.25
SAME_POINT_RADIUS = 80

active = False
position = (0, 0)
last_touch = 0

touches = deque()
lock = threading.Lock()
shutdown_event = threading.Event()

shell = subprocess.Popen(
    ["adb", "shell"],
    stdin=subprocess.PIPE,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1
)


def tap(x, y):
    try:
        shell.stdin.write(f"input tap {x} {y}\n")
        shell.stdin.flush()
    except (BrokenPipeError, OSError):
        shutdown_event.set()


def calculate_distance(point1, point2):
    return math.hypot(
        point1[0] - point2[0],
        point1[1] - point2[1]
    )


def register_touch(x, y):
    global active, position, last_touch

    current_time = time.monotonic()
    current_position = (x, y)

    with lock:

        if active:

            if calculate_distance(
                current_position, position
            ) <= SAME_POINT_RADIUS:

                position = current_position
                last_touch = current_time
                return

            active = False
            touches.clear()

            print("is disabled.")

        while touches and (
            current_time - touches[0][0] > TRIGGER_WINDOW
        ):
            touches.popleft()

        recent_touches = [
            touch for touch in touches
            if calculate_distance(
                (touch[1], touch[2]),
                current_position
            ) <= SAME_POINT_RADIUS
        ]

        touches.clear()
        touches.extend(recent_touches)

        touches.append((current_time, x, y))

        if len(touches) >= TRIGGER_CLICKS:

            active = True
            position = current_position
            last_touch = current_time

            touches.clear()

            print(
                f"\n[+] IS ACTIVATED at {position}"
                f" | +{EXTRA_CPS} CPS"
            )


def click_loop():

    next_click = time.monotonic()

    while not shutdown_event.is_set():

        current_time = time.monotonic()

        with lock:
            enabled = active and (
                current_time - last_touch <= ACTIVE_TIMEOUT
            )

            x, y = position

            if active and not enabled:
                globals()["active"] = False
                print("just stop.")

        if enabled and current_time >= next_click:

            tap(x, y)

            next_click = (
                time.monotonic() + CLICK_INTERVAL
            )

        else:
            time.sleep(0.005)


def monitor_touches():

    process = subprocess.Popen(
        [
            "adb", "shell",
            "getevent", "-lt", DEVICE
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    x = None
    y = None

    print("CPS auto started")
    print("perform 2 rapid touches at the same position.")
    print("the booster stops when you stop touching.\n")

    try:

        for line in process.stdout:

            if shutdown_event.is_set():
                break

            parts = line.strip().split()

            if len(parts) < 4:
                continue

            event = parts[-2]
            value = parts[-1]

            if event == "ABS_MT_POSITION_X":
                x = int(value, 16)

            elif event == "ABS_MT_POSITION_Y":
                y = int(value, 16)

            elif event == "BTN_TOUCH" and value == "DOWN":

                if x is not None and y is not None:
                    register_touch(x, y)

    except KeyboardInterrupt:
        pass

    finally:

        shutdown_event.set()
        process.terminate()

        try:
            shell.stdin.close()
        except Exception:
            pass

        shell.terminate()

        print("CPS terminated.")


if __name__ == "__main__":

    thread = threading.Thread(
        target=click_loop,
        daemon=True
    )

    thread.start()

    monitor_touches()
