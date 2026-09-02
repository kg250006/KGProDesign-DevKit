#!/bin/bash
cd "$(dirname "$0")"
python3 -c "import pystray, PIL" 2>/dev/null || pip3 install -r requirements.txt
nohup python3 cronlike.py &>/dev/null &
osascript -e 'tell application "Terminal" to close front window' &
