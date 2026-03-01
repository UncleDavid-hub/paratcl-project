# NAME
paracomms - ParaTcl inter-node communication module

# SYNOPSIS
```tcl
paracomms::init
paracomms::send_command peer cmd
paracomms::broadcast_command peers cmd
```

# DESCRIPTION
The `paracomms` module handles all Tcl-based communication between nodes using the `comm` package. It includes a security model based on safe interpreters to restrict what commands can be executed remotely.

# COMMANDS
**paracomms::init**
Initializes the communication channel and creates the restricted slave interpreter. Returns the local `comm` ID.

**paracomms::send_command** *peer* *cmd*
Sends a Tcl command to the specified *peer* ID. Returns the result of the remote execution.

**paracomms::broadcast_command** *peers* *cmd*
Sends the same command to a list of *peers*.

# SECURITY
Incoming commands are executed in a safe interpreter. Only the following commands are allowed:
- `::paravar::remote_update`
- `::paragui::log`
- `::paravar::update_peers`

# SEE ALSO
paratcl(n), comm(n)
