# Welcome to ParaTcl! 🚀 *** ALMOST *** ready to launch - hardware support simulated for now !

ParaTcl is a unified parallel Tcl engine running on multiple hosts. <img width="2304" height="1728" alt="paratcl" src="https://github.com/user-attachments/assets/e3359e86-d873-439a-9593-2ab5ca9de027" />
  This 64-bit version is optimized for high-performance systems with **MPI** and **CUDA** support.

## 🚀 Quick Start for Beginners

Follow these easy steps to see ParaTcl in action:

### Step 1: Install Tcl
Open your terminal and type:
```bash
sudo apt-get update
sudo apt-get install tcl tcl-udp tk
```

### Step 2: Run the Demo
Open two terminal windows.

**In the first terminal (The Master):**
```bash
tclsh demo.tcl 1
```

**In the second terminal (The Worker):**
```bash
tclsh demo.tcl 0
```

### What happens?
- The **Master** starts a GUI and listens for peers.
- The **Worker** automatically discovers the Master on the network.
- They share a "Parallel Variable"—change it in one window, and it updates in the other!

## 🛠️ Exploring the Architecture
Check out `whitepaper.md` for a deep dive into how it works, and look in the `doc/` folder for the full manual.

## 🌟 Features
- **Auto-Discovery:** Nodes find each other on the network automatically.
- **Parallel Variables:** Seamless distributed state synchronization.
- **HPC Ready:** Full support for MPI and NVIDIA CUDA.
- **Secure:** Uses safe interpreters for remote command execution.

Happy Computing!
