# Welcome to ParaTcl! 🚀 The Grand Unified Parallel Engine

ParaTcl is a single, architecture-aware codebase that brings high-performance computing to any hardware you own. Whether you're running on a modern liquid-cooled workstation, a distributed cluster of Raspberry Pis, or a collection of legacy 32-bit PCs, ParaTcl "just works" out of the box.

<img width="2304" height="1728" alt="paratcl" src="https://github.com/user-attachments/assets/e3359e86-d873-439a-9593-2ab5ca9de027" />

## 🌟 Three Tiers, One Engine

ParaTcl automatically detects your hardware and scales its capabilities:

1.  **Modern x86_64:** Unleashes the full power of **MPI** and **NVIDIA CUDA** cores.
2.  **Raspberry Pi / ARM:** Distributed supercomputing on the Pi 4b with **Vulkan** compute shaders and real-time cluster health monitoring.
3.  **Legacy x86_32:** Breathe new life into older hardware with **MPI-only** horizontal scaling.

## 🚀 Quick Start

### Step 1: Install Tcl
Open your terminal and type:
```bash
sudo apt-get update
sudo apt-get install tcl tcl-udp tk
```

### Step 2: Run the Demo
Open two terminal windows.

**Terminal 1 (Master):** `tclsh demo.tcl master`
**Terminal 2 (Worker):** `tclsh demo.tcl`

### Step 3: Verify your Hardware
Run the new diagnostic tool to see your system's capabilities:
```bash
tclsh diagnostics.tcl
```

ParaTcl will automatically detect your architecture and tell you exactly which packages to install (like `openmpi-bin`, `nvidia-cuda-toolkit`, or `mesa-vulkan-drivers`) to reach peak performance!

## 🛠️ Exploring the Architecture
Check out `whitepaper.md` for a deep dive into the Grand Unification strategy, and look in the `doc/` folder for the full manual.

## 🌟 Features
- **Auto-Discovery:** Nodes find each other on the network automatically.
- **Parallel Variables:** Seamless distributed state synchronization via Tcl `trace`.
- **Hardware Agnostic:** Optimized for x86_64, ARM, and x86_32.
- **Cluster Health:** Integrated temperature and throttling monitor for Pi clusters.

Happy Computing across all generations!
