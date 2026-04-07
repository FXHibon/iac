#!/bin/zsh

set -eax

scp -r . "rp5:/home/fxhibon/apps/"

ssh rp5 << 'EOF'
    cd /home/fxhibon/apps/
    docker compose up -d --remove-orphans --force-recreate --pull always
EOF 2> /dev/null
