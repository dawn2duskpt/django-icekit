#!/bin/bash

# Wrapper for 'entrypoint.sh' that defines 'ICEKIT_DIR' and
# 'ICEKIT_PROJECT_DIR', environment variables.

cat <<EOF
# `whoami`@`hostname`:$PWD$ go.sh $@
EOF

set -e

# We need to run additional services with Supervisord when not using Docker.
export EXTRA_SUPERVISORD_CONFIG=supervisord-no-docker.conf

# Get absolute project directory from the location of this script.
# See: http://stackoverflow.com/a/4774063
export ICEKIT_PROJECT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd -P)

# Use alternate installation (user scheme) for Python packages.
export PIP_SRC="$ICEKIT_PROJECT_DIR/venv/src"
export PYTHONUSERBASE="$ICEKIT_PROJECT_DIR/venv"

# Install ICEkit, if necessary.
if [[ -z $(pip freeze | grep django-icekit) ]]; then
    pip install --user -r requirements.txt
fi

# Get absolute directory for the `icekit` package.
export ICEKIT_DIR=$(python -c 'import icekit, os; print os.path.dirname(icekit.__file__);')

# Execute wrapped entrypoint script.
exec "$ICEKIT_DIR/bin/entrypoint.sh" "$@"
