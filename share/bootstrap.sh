#!/bin/bash -eu
###############################################################################
# Punch default bootstrap template

{{#PUNCH_BOOTSTRAP_PRIVATE_KEY}}
###############################################################################
# SSH keys
# Install an SSH private key so we can download bootstrap resources via ssh

mkdir -p ~/.ssh
cat <<EOF > ~/.ssh/id_rsa
{{PUNCH_BOOTSTRAP_PRIVATE_KEY}}
EOF

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa

{{/PUNCH_BOOTSTRAP_PRIVATE_KEY}}
{{#PUNCH_BOOTSTRAP_GIT_URL}}{{#PUNCH_BOOTSTRAP_GIT_DIR}}
###############################################################################
# Bootstrap scripts
# Download bootstrap scripts using git

apt-get update
apt-get install -y git

{{#BOOTSTRAP_GIT_SSH_HOST}}
ssh-keyscan {{PUNCH_BOOTSTRAP_GIT_SSH_HOST}} >> ~/.ssh/known_hosts
{{/BOOTSTRAP_GIT_SSH_HOST}}
git clone --depth 1 --branch develop {{PUNCH_BOOTSTRAP_GIT_URL}} {{PUNCH_BOOTSTRAP_GIT_DIR}}

{{/PUNCH_BOOTSTRAP_GIT_DIR}}{{/PUNCH_BOOTSTRAP_GIT_URL}}
###############################################################################
# Bootstrap
# Run the bootstrap script

export DEBIAN_FRONTEND=noninteractive

{{PUNCH_BOOTSTRAP_SCRIPT}}

echo
echo "Punch bootstrap complete"
