# shellcheck shell=bash
# no need for shebang - this file is loaded from charts.d.plugin
# SPDX-License-Identifier: GPL-3.0-or-later

# netdata
# real-time performance and health monitoring, done right!
#
# iptmon - a netdata plugin for IPTMon on OpenWRT
# (C) 2021 Ingo Ratsdorf <ingo@envirology.co.nz>
#

# _update_every is a special variable - it holds the number of seconds
# between the calls of the _update() function
iptmon_update_every=

# the priority is used to sort the charts on the dashboard
# 1 = the first chart
iptmon_priority=7000

# global variables to store our collected data
# remember: they need to start with the module name iptmon_
iptmon_rx_chain='iptmon_rx'
iptmon_tx_chain='iptmon_tx'
iptmon_last=0
iptmon_count=0

declare -A iptmon_ips=()

# _check is called once, to find out if this chart should be enabled or not
iptmon_check() {
  # this should return:
  #  - 0 to enable the chart
  #  - 1 to disable the chart

  require_cmd iptmon || return 1
  return 0
}

# _create is called once, to create the charts
iptmon_create() {

# create the chart with 256 dimensions
# TODO: This chart should have host NAMES for the dimensions, but the chart would need dynamically recreation when a host comes onboard
echo "CHART iptmon.received 'KBytes received' 'KBytes' 'KBytes since last update' iptmon.received area $iptmon_priority $iptmon_update_every"
for i in {0..255}
do
  echo "DIMENSION received.192.168.1.$i 192.168.1.$i incremental 1 1024"
done
echo
echo "CHART iptmon.sent 'KBytes sent' 'KBytes' 'KBytes since last update' iptmon.sent area $iptmon_priority $iptmon_update_every"
for i in {0..255}
do
  echo "DIMENSION sent.192.168.1.$i 192.168.1.$i incremental 1 1024"
done

  return 0
}

# _update is called continuously, to collect the values
iptmon_update() {
  # the first argument to this function is the microseconds since last update
  # pass this parameter to the BEGIN statement (see bellow).

  local rx
  local tx

  # Get all iptmon chain for receiving data, we only do IP4, IP6 has a row less data, TODO
  rx=`iptables -nvx -t mangle -L $iptmon_rx_chain`
  # Get all iptmon chain for sending data, we only do IP4, IP6 has a row less data, TODO
  tx=`iptables -nvx -t mangle -L $iptmon_tx_chain`

  # write the result of the work.

  echo "$rx" | awk 'BEGIN {
    print "BEGIN iptmon.received " $1
    } {
      if ($1 ~ /\d/ && $8 !~ /127.0.0.1/) {
          print "SET received." $8 " = " $2
      }
    }
    END {
      print "END"
    }'

echo "$tx" | awk 'BEGIN {
    print "BEGIN iptmon.sent " $1
    } {
      if ($1 ~ /\d/ && $9 !~ /127.0.0.1/) {
        print "SET sent." $9 " = " $2
      }
    }
    END {
      print "END"
    }'

  return 0
}
