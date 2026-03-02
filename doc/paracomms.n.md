# NAME
paracomms - Secured communication layer for ParaTcl

# SYNOPSIS
```tcl
paracomms::init
paracomms::send_command peer cmd
paracomms::broadcast_command peers cmd
```

# DESCRIPTION
The `paracomms` module handles all inter-node communication using the Tcl `comm` package.

# SECURITY: SLAVE INTERPRETERS
To prevent unauthorized code execution, `paracomms` creates a restricted **Slave Interpreter** (named `slave`).
- All incoming commands from remote nodes are executed within this slave.
- Only a strict whitelist of commands are aliased into the slave:
    - `::paravar::remote_update`
    - `::paragui::log`
    - `::paravar::update_peers`
- Any attempt to execute other commands (like `exec`, `file`, etc.) will fail.

# COMMANDS
**paracomms::init**
Initializes the communication layer, creates the secured slave interpreter, and returns the local `comm` ID.

**paracomms::send_command** *peer cmd*
Sends a command to a specific peer. The command will be executed in the peer's slave interpreter.

**paracomms::broadcast_command** *peers cmd*
Sends the same command to a list of peers.

# SEE ALSO
paratcl(n), paravar(n)
