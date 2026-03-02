# NAME
bootknife - The ParaTcl fallback deployment philosophy

# DESCRIPTION
"Bootknife" mode is ParaTcl's resilient execution strategy. It ensures that the application remains functional even when high-performance dependencies or hardware are unavailable.

# ACTIVATION
Bootknife mode is automatically activated by `hardware::detect` if any of the following are missing:
- `mpirun` or `mpiexec` (MPI)
- `nvcc` (CUDA Compiler)
- `ssh` (Secure Shell)
- `critcl` (Tcl C-extension package)

# BEHAVIOR
When in Bootknife mode, the following behavioral changes occur:

### 1. Local-Only Execution
MPI cluster spawning is skipped. The application runs as a single process on the local machine. Parallel variables still synchronize if other nodes are discovered via UDP, but no automatic cluster deployment occurs.

### 2. CPU Fallback
Calls to `hardware::cuda_offload` are redirected to `hardware::cpu_fallback`. This ensures that logic intended for the GPU still executes, albeit at lower performance, using the host processor.

### 3. User Guidance
Instead of failing with an error, ParaTcl provides "TIP" messages in the `hardware::status` output. These tips guide the user on how to resolve the missing dependencies to exit Bootknife mode.

# PHILOSOPHY
The name "Bootknife" refers to a reliable, always-available tool that serves as a backup when larger equipment is unavailable. This allows for a smooth development-to-production pipeline:
1. **Develop** in Bootknife mode on a standard laptop.
2. **Test** logic using local CPU fallbacks.
3. **Deploy** to a supercomputer where the same code automatically scales using MPI and CUDA.

# SEE ALSO
hardware(n), paratcl(n)
