#!/bin/bash
cd "$(dirname "$0")"
echo "Installing dependencies..."
pip install -r requirements.txt
echo ""
echo "Done! Start CronLike with: python3 cronlike.py"
