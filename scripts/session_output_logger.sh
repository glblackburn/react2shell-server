#!/usr/bin/env bash
# Session output logger - saves all commands to timestamped files
# Source this file to enable automatic logging

SESSION_START=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="/tmp/session_logs_${SESSION_START}"
mkdir -p "$SESSION_LOG_DIR"

# Function to log command output
log_command() {
    local cmd="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="${SESSION_LOG_DIR}/cmd_${timestamp}.txt"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running: $cmd" | tee -a "${SESSION_LOG_DIR}/session.log"
    eval "$cmd" 2>&1 | tee "$log_file"
    local exit_code=${PIPESTATUS[0]}
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Exit code: $exit_code" | tee -a "${SESSION_LOG_DIR}/session.log"
    echo "Output saved to: $log_file" | tee -a "${SESSION_LOG_DIR}/session.log"
    echo "" | tee -a "${SESSION_LOG_DIR}/session.log"
    
    return $exit_code
}

echo "Session logging enabled"
echo "Session log directory: $SESSION_LOG_DIR"
echo "Use: log_command '<command>' to run and log commands"
