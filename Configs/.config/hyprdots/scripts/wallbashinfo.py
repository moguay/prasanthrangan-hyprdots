#!/usr/bin/env python3

import json
import os
import time
import sys

# Get the path of the current directory
current_dir = os.path.dirname(os.path.abspath(__file__))

# Build the file path
file_path = os.path.join(current_dir, 'globalcontrol.sh')

def check_variable():
    with open(file_path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if "EnableWallDcol=" in line:
                return line.split('=')[1].strip()

def create_json(value):
    if value == '0':
        return {'text': '',
                'tooltip': ' Color Theme\n󰳽 <small>click-left: 󰔢 switch color</small>',
                'class': 'color',
                'alt': 'theme'}
    elif value == '1':
        return {'text': '',
                'tooltip': '󰃣 Color Wall\n󰳽 <small>click-left: 󰔢 switch color</small>',
                'class': 'color',
                'alt': 'wall'}

def main():
    while True:
       value = check_variable()
       output = create_json(value)
       sys.stdout.write(json.dumps(output) + '\n')
       sys.stdout.flush()
       time.sleep(1)

if __name__ == "__main__":
    main()
