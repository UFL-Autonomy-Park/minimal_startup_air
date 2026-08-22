#!/bin/bash
export PX4_HOME_LAT=29.6282091
export PX4_HOME_LON=-82.36033457
export PX4_HOME_ALT=24.27512038
export PX4_GZ_WORLD=autonomy_park

# pkill -9 -f "gz|gazebo|px4"

# ~/PX4-Autopilot/build/px4_sitl_default/bin/px4-commander set_ekf_origin 29.6282091 -82.36033457 24.27512038

PX4_DIR=~/PX4-Autopilot
READY_STRING="Ready for takeoff!"


launch_px4() {
    local instance=$1
    local autostart=$2
    local model=$3
    local pose=${4:-}
    local logfile="/tmp/px4_instance_${instance}.log"

    echo "[*] Launching PX4 instance $instance (model=$model, autostart=$autostart)..."

    # -d disables px4's interactive "pxh>" shell. Without it, px4's getchar()
    # read loop never blocks once stdin isn't a real controlling terminal (as
    # here, backgrounded from a script) - it spins re-printing the prompt as
    # fast as the CPU allows, pegging a core and growing $logfile without
    # bound instead of settling down after startup.

    PX4_HOME_LAT="$PX4_HOME_LAT" \
    PX4_HOME_LON="$PX4_HOME_LON" \
    PX4_HOME_ALT="$PX4_HOME_ALT" \
    PX4_GZ_WORLD="$PX4_GZ_WORLD" \
    PX4_SYS_AUTOSTART="$autostart" \
    PX4_SIM_MODEL="$model" \
    PX4_GZ_MODEL_POSE="$pose" \
    "$PX4_DIR/build/px4_sitl_default/bin/px4" -i "$instance" -d < /dev/null > "$logfile" 2>&1 &

    echo "PID: $!"
}

wait_for_ready() {
    local instance=$1
    local logfile="/tmp/px4_instance_${instance}.log"
    local timeout=30  # seconds
    local elapsed=0

    echo "[*] Waiting for instance $instance to be ready..."

    while (( elapsed < timeout )); do
        if grep -q "$READY_STRING" "$logfile" 2>/dev/null; then
            echo "[+] Instance $instance is ready!"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo "[!] Timeout waiting for instance $instance. Check $logfile" >&2
    return 1
}


# --- Launch sequence ---

cd $PX4_DIR

# Instance 1 - Spawns at X=6 (8 - 2), Y=65 and loads Gazebo world
launch_px4 0 22000 gz_homebrew "0,20"
wait_for_ready 0

echo "[+] All instances ready!"

# Keep script alive so background processes don't get killed
wait