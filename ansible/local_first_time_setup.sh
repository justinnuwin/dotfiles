#!/bin/bash

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [[ ! -d venv ]]; then
  python -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
else
  source venv/bin/activate
fi

ansible-playbook first_time_setup.yml --connection=local --inventory 127.0.0.1, --limit 127.0.0.1
