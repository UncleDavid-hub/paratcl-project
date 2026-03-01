# NAME
paratcl - ParaTcl main initialization and control module

# SYNOPSIS
```tcl
paratcl::init master_flag ?discovery_port?
```

# DESCRIPTION
The `paratcl` module is the primary entry point for ParaTcl applications. It orchestrates the initialization of all sub-modules (comms, hardware, discovery, gui, worker) and manages the main event loop for peer monitoring.

# COMMANDS
**paratcl::init** *master_flag* ?*discovery_port*?
Initializes the ParaTcl node. 
- *master_flag*: Boolean. If 1, the node starts as a MASTER. If 0, it starts as a WORKER.
- *discovery_port*: Optional. The UDP port to use for node discovery (defaults to 9999).

# EXAMPLES
```tcl
# Start as a master node on default port
paratcl::init 1

# Start as a worker node
paratcl::init 0
```

# SEE ALSO
paracomms(n), paravar(n), discovery(n), hardware(n)
