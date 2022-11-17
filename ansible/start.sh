#!/bin/bash
set -u          # Treat unset variables as an error when substituting
set -e          # Exit if any command returns a non-zero status
set -o pipefail # Same for piped commands

# launching the php service like this to preserve env vars
/etc/init.d/php8.0-fpm start
# start the nginx service
service nginx start
# follow the log to show on docker stdout
tail -n 0 -F /var/log/nginx/access.log