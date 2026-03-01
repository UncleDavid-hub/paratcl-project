# NAME
discovery - ParaTcl node discovery module

# SYNOPSIS
```tcl
discovery::init comm_port ?dport?
discovery::get_peers
```

# DESCRIPTION
The `discovery` module implements an automated peer discovery mechanism using UDP broadcasting. It allows nodes to find each other on the local network without manual configuration.

# COMMANDS
**discovery::init** *comm_port* ?*dport*?
Starts the discovery service.
- *comm_port*: The local communication ID (from `paracomms::init`) to advertise.
- *dport*: Optional. The UDP port to use for broadcasts (defaults to 9999).

**discovery::get_peers**
Returns the list of discovered peer communication IDs.

# BEHAVIOR
- Broadcasts a "HELLO [id]" message every 5 seconds.
- Listens for broadcasts from other nodes and updates a local peer registry.
- Supports multiple instances on the same host via socket reuse.

# SEE ALSO
paratcl(n), paracomms(n)
