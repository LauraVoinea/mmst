#!/bin/sh
#
# The playground's container, in the foreground, for the service mmst.
#
# Its memory limit is the machine's memory less 640 MB for the system, Docker and Caddy, and
# container.sh sizes the playground to that limit: after a resize, a restart resizes it too.
# Its file system is read-only but for two small scratch areas: /tmp, for the server alone, and
# the runs' folders. It keeps only the capabilities the server needs to give each run its own
# user and clean up after it, cannot gain more, and has at most 1024 processes and threads.
# /opt/mmst/env, if there, sets the container's variables, one NAME=value a line.

set -eu

total=$(awk '/^MemTotal:/ { print int($2 / 1024) }' /proc/meminfo)
limit=$((total - 640))
if [ -f /opt/mmst/env ]; then set -- --env-file /opt/mmst/env; fi

exec docker run --rm --name mmst --pull never \
  --publish 127.0.0.1:10000:10000 \
  --memory "${limit}m" --memory-swap "${limit}m" \
  --read-only \
  --tmpfs /tmp:rw,mode=700,size=128m \
  --tmpfs /var/lib/mmst/runs:rw,mode=711,size=128m \
  --cap-drop ALL \
  --cap-add CHOWN --cap-add DAC_OVERRIDE --cap-add FOWNER --cap-add KILL \
  --cap-add SETGID --cap-add SETUID --cap-add SETPCAP \
  --security-opt no-new-privileges \
  --pids-limit 1024 \
  --log-driver local \
  "$@" mmst-playground
