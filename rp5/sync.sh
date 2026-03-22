#!/bin/zsh

set -eax

scp -r . "rp5-internal:/home/fxhibon/apps/"

ssh fxhibon@rp5-internal << 'EOF'
    cd /home/fxhibon/apps/
    docker compose up -d --remove-orphans
EOF 2> /dev/null
