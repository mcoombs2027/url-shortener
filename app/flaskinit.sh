#!/usr/bin/bash

echo "flask.service: ## Starting up ##" | systemd-cat -p info
export FLASK_APP=routes

cd "$(dirname "$0")"

flask run -h 0.0.0.0 &
