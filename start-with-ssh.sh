#!/bin/bash

# Start SSH service first
service ssh start

# Execute the original entrypoint (this becomes the main process)
exec /opt/start.sh
