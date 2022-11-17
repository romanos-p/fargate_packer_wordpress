#!/bin/bash
set -u          # Treat unset variables as an error when substituting
set -e          # Exit if any command returns a non-zero status
set -o pipefail # Same for piped commands

# install required packages
export DEBIAN_FRONTEND="noninteractive"
apt-get update
apt-get install apt-utils gzip python3 python3-pip -y
