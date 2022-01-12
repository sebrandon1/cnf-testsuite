#!/bin/bash

RUNNERS=(
    136.144.55.87
    136.144.55.243
    139.178.69.151
    139.178.69.153
    139.178.68.167
    86.109.1.243
    139.178.68.111
    139.178.68.103
    139.178.68.93
    139.178.68.107
    136.144.54.249)

VIPS=(
    147.75.89.176/28
    147.75.108.64/28
    147.75.202.0/28
    147.75.202.80/28
    147.75.88.0/28
    147.75.202.112/28
    147.75.203.112/28
    147.75.203.144/28
    147.75.203.160/28
    147.75.203.176/28
    147.75.203.192/28)


RUNNER_COUNT=0
for node in "${!RUNNERS[@]}"; do
    ssh root@${RUNNERS[$node]} "docker pull conformance/github-runner:v2.285.1"
    RUNNERS_PER_NODE=16
    until [ $RUNNERS_PER_NODE -eq 0 ]; do
        ssh root@${RUNNERS[$node]} "docker run -d --network host --restart always --name github-runner$RUNNER_COUNT -e REPO_URL="https://github.com/cncf/cnf-testsuite" -e RUNNER_NAME="runner$RUNNER_COUNT" -e RUNNER_TOKEN="$TOKEN" -e RUNNER_WORKDIR="/github-runner-cnf-testsuite" -e LABELS="v1.0.0" -v /var/run/docker.sock:/var/run/docker.sock -v /runner-tmp/runner$RUNNER_COUNT:/tmp -v /github-runner-cnf-testsuite/cnf-testsuite/cnf-testsuite/tools:/docker-host-repo/tools -v /shared:/shared conformance/github-runner:v2.285.1"
        RUNNER_COUNT=$(($RUNNER_COUNT + 1))
        RUNNERS_PER_NODE=$(($RUNNERS_PER_NODE - 1))
    done
    ssh root@${RUNNERS[$node]} "docker network rm kind"
    ssh root@${RUNNERS[$node]} docker network create --driver bridge --subnet=${VIPS[$node]} --opt "com.docker.network.bridge.name"="kindbridge" --opt "com.docker.network.bridge.enable_ip_masquerade"="false" kind
    ssh root@${RUNNERS[$node]} sudo chmod 777 /runner-tmp -R
    # ssh root@${RUNNERS[$node]} "sudo apt update && sudo apt install -y bridge-utils"
   # ssh root@${RUNNERS[$node]} "sudo brctl addif kindbridge bond0"
done

