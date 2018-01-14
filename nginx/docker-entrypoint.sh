#!/bin/sh

# Exit script in case of error
set -e

ls

printf "\n\nLoading nginx autoreloader\n"
sh /docker-autoreload.sh &


# Run the CMD 
exec "$@"