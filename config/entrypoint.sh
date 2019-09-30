#!/bin/sh

set -e
set -u

# Run startup scripts

if [ "$(ls /inittask/)" ]; then
  for init in /inittask/*.sh; do
    sh $init
  done
  # no need to run it again
  rm -f /inittask/*.sh
fi

# If we have an interactive container
if test -t 0; then
  # Execute commands passed to container and exit, or run bash
  if [ "$#" -gt 0 ]; then
    eval "exec $@"
  else 
    exec /bin/sh
  fi

# If container is detached run superviord in the foreground 
else
  if [ "$#" -gt 0 ]; then
    eval "exec $@"
  else 
    exec /usr/bin/supervisord -c /etc/supervisord.conf
  fi
fi
