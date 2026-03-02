# NAME
hardware - ParaTcl hardware detection and acceleration module

# SYNOPSIS
```tcl
hardware::detect
hardware::status
hardware::manage_hosts
hardware::mpi_run cmd
hardware::cuda_offload kernel_name code_snippet inputs outputs
```

# DESCRIPTION
The `hardware` module is responsible for detecting high-performance computing resources such as MPI (Message Passing Interface) and CUDA (NVIDIA GPU acceleration). It handles the transition from simulated mode to actual hardware execution.

# COMMANDS
**hardware::detect**
Scans the environment for `mpirun`, `mpiexec`, `nvcc`, `ssh`, and the `critcl` Tcl package. Returns a list containing four booleans: {mpi_present cuda_present ssh_present critcl_present}.

**hardware::status**
Prints a detailed human-readable summary of detected hardware and missing dependencies, including tips for installation and configuration.

**hardware::manage_hosts**
Reads the `hosts.para` file, performs connectivity checks via passwordless SSH, and generates a `hosts.para.runtime` file containing only valid, reachable nodes.

**hardware::mpi_run** *cmd*
Attempts to launch the current script across the cluster defined in `hosts.para.runtime`. If no cluster is active, it falls back to local execution. Returns 1 on successful cluster launch, 0 otherwise.

**hardware::cuda_offload** *kernel_name code_snippet inputs outputs*
Offloads computation to a GPU. If CUDA or `critcl` is missing, it automatically uses `cpu_fallback`.
- *kernel_name*: Name for the generated Tcl command.
- *code_snippet*: Raw CUDA C code.
- *inputs*: List of input variables.
- *outputs*: List of output variables.

# FILES
`hosts.para` - User-defined list of potential cluster nodes.
`hosts.para.runtime` - Automatically generated list of active, reachable nodes.

# SEE ALSO
paratcl(n), hosts.para(5), bootknife(7)
