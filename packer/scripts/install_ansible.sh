#!/bin/bash
set -u          # Treat unset variables as an error when substituting
set -e          # Exit if any command returns a non-zero status
set -o pipefail # Same for piped commands

# install ansible
python3 -m pip install ansible
# test that installation was successfull
ansible --version > /dev/null 2>&1 || ( echo "ERROR: Ansible was not installed" && exit 1 )
echo "Successfully installed Ansible"
