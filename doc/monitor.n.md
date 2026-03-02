# monitor.n.md - ParaTcl Cluster Health Monitor

## NAME
monitor - Real-time cluster-wide health monitoring dashboard.

## SYNOPSIS
`package require cluster_monitor`

`::cluster_monitor::init` host_list

## DESCRIPTION
The `cluster_monitor` module provides a Tk-based graphical dashboard for monitoring the thermal and throttling status of all nodes in a Raspberry Pi or other Linux-based compute cluster.

### Commands
- `::cluster_monitor::init host_list`: Initializes the monitor with a list of cluster hostnames.
- `::cluster_monitor::poll_nodes`: Iterates through the host list and fetches temperature and throttling data via SSH.

## DATA SOURCES
- **Temperature**: Fetched from `/sys/class/thermal/thermal_zone0/temp`.
- **Throttling Status**: Fetched via the `vcgencmd get_throttled` command (specific to Raspberry Pi).

## USAGE
The monitor is automatically enabled by default in `paratcl::init` if the current node is the master.
