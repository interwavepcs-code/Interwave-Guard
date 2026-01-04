# Interwave Guard

Interwave Guard is a plug-and-play network appliance that blocks ads, trackers,
and malicious domains for every device on a network.

Built on open-source software. No subscriptions. No cloud dependency.

---

## What it does
- Network-wide ad & tracker blocking
- Works with phones, PCs, smart TVs, consoles
- Local DNS resolution with Unbound
- Optional remote access via Tailscale

## What it does NOT do
- Does not block YouTube ads
- Does not block Netflix ads

---

## Hardware
Designed for:
- Raspberry Pi Zero 2 W
- 16 GB microSD card (recommended)

---

## Installation (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/interwavepcs-code/Interwave-Guard/main/install/appliance-install.sh | sudo bash
