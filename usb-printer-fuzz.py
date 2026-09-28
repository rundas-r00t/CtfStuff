#!/usr/bin/env python3
"""USB printer fuzzer — writes directly to /dev/usb/lp0"""
import os
import time

DEV = "/dev/usb/lp0"

def send_raw(payload: bytes, label: str):
    try:
        fd = os.open(DEV, os.O_WRONLY)
        os.write(fd, payload)
        os.close(fd)
        # Brief read attempt for any PJL response
        try:
            fd_r = os.open(DEV, os.O_RDONLY | os.O_NONBLOCK)
            resp = os.read(fd_r, 4096)
            os.close(fd_r)
        except (BlockingIOError, OSError):
            resp = b""
        print(f"[{label}] sent {len(payload)}b, resp: {resp[:80]!r}")
    except Exception as e:
        print(f"[{label}] ERROR: {e}")

UEL = b"\x1b%-12345X"

# PJL queries — these do get responses over USB
send_raw(UEL + b"@PJL INFO ID\r\n" + UEL, "INFO ID")
time.sleep(1)
send_raw(UEL + b"@PJL FSDIRLIST NAME=\"0:\\\" ENTRY=1 COUNT=50\r\n" + UEL, "DIRLIST")
time.sleep(1)

# Raw PS jobs — no response expected, monitor for crash
PS = b"%!PS-Adobe-3.0\n65535 65535 string pop\nshowpage\n%%EOF\n"
send_raw(PS, "mem-exhaust")
time.sleep(2)
