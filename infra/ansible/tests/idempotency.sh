#!/usr/bin/env bash
# Converge the throwaway test containers twice and fail unless the second run changes nothing.
# Runs inside the controller image; see infra/README.md for the docker commands around it.
#   tests/idempotency.sh gpu-node.yml iac-test-ubuntu
set -euo pipefail
cd "$(dirname "$0")/.."
playbook=$1
host=$2
export ANSIBLE_CONFIG=$PWD/ansible.cfg
export TS_AUTHKEY=""   # never join a tailnet from the test

for run in 1 2; do
  log=/tmp/${host}-run${run}.log
  start=$(date +%s)
  ansible-playbook -i inventory/test.yml -l "$host" "$playbook" >"$log" 2>&1 || { tail -40 "$log"; exit 1; }
  echo "run $run: $(( $(date +%s) - start ))s  $(grep -E "^${host} +:" "$log" | tr -s ' ')"
done

changed=$(grep -E "^${host} +:" /tmp/${host}-run2.log | sed -E 's/.*changed=([0-9]+).*/\1/')
if [[ "$changed" != "0" ]]; then
  echo "NOT idempotent: second run changed=$changed"
  grep -E '^changed:' /tmp/${host}-run2.log || true
  exit 1
fi
echo "idempotent: second run changed=0"
