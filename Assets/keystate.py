#!/usr/bin/env python3

import struct
import sys
import os
from pathlib import Path

EV_LED = 0x11
LED_NUML = 0x00
LED_CAPSL = 0x01

def write_state(name, value):
    cache_dir = Path.home() / ".cache" / "keystate"
    cache_dir.mkdir(parents=True, exist_ok=True)
    state_file = cache_dir / name
    state_file.write_text("true" if value else "false")

def read_input_events(device_path):
    EVENT_FORMAT = 'llHHi'
    EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
    
    with open(device_path, 'rb') as kbd:
        while True:
            event_data = kbd.read(EVENT_SIZE)
            if len(event_data) < EVENT_SIZE:
                break
            
            _, _, ev_type, ev_code, ev_value = struct.unpack(EVENT_FORMAT, event_data)
            
            if ev_type == EV_LED:
                if ev_code == LED_CAPSL:
                    write_state("capslock", ev_value)
                elif ev_code == LED_NUML:
                    write_state("numlock", ev_value)

if __name__ == "__main__":
    device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
    if len(sys.argv) > 1:
        device = sys.argv[1]
    
    read_input_events(device)
