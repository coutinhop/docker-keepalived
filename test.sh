#!/bin/bash
# Copyright 2025 Pedro Coutinho
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

RETURN_VALUES=""

IMAGE_NAME=${IMAGE_NAME:=ghcr.io/coutinhop/docker-keepalived}
IMAGE_TAG=${IMAGE_TAG:=latest}
ARCH=$(uname -m)
ARCH=$(echo $ARCH | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/' -e 's/armv7l/arm/')

TEST_PREFIX=docker-keepalived-test

echo "Pre-test clean up"
docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
docker network rm -f ${TEST_PREFIX}-net || true

echo "Creating test network"
docker network create ${TEST_PREFIX}-net
TEST_SUBNET=$(docker network inspect ${TEST_PREFIX}-net -f json | jq -r '.[0].IPAM.Config.[0].Subnet')
echo "Test network subnet:" $TEST_SUBNET
TEST_SUBNET=$(echo $TEST_SUBNET | cut -d'/' -f1 | cut -d'.' -f1,2,3)
TEST_IP1=${TEST_SUBNET}.2
TEST_IP2=${TEST_SUBNET}.3
TEST_VIP=${TEST_SUBNET}.4/24
echo "Test network IP1:" $TEST_IP1 " IP2:" $TEST_IP2 " VIP:" $TEST_VIP

echo "Starting test case 1: 01-OK 02-OK"
RETURN_VALUE=0
docker run -d --name ${TEST_PREFIX}-1 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/true" \
    -e KEEPALIVED_SRC_IP=${TEST_IP1}\
    -e KEEPALIVED_PEER_IP=${TEST_IP2}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-01\
    -e KEEPALIVED_INSTANCE_NAME=keepalived1\
    -e KEEPALIVED_PRIORITY=150\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
docker run -d --name ${TEST_PREFIX}-2 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/true" \
    -e KEEPALIVED_SRC_IP=${TEST_IP2}\
    -e KEEPALIVED_PEER_IP=${TEST_IP1}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-02\
    -e KEEPALIVED_INSTANCE_NAME=keepalived2\
    -e KEEPALIVED_PRIORITY=145\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
sleep 10
docker logs ${TEST_PREFIX}-1 > ./test-1-1.log 2>&1
docker logs ${TEST_PREFIX}-2 > ./test-1-2.log 2>&1

MSG1="(keepalived1) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) succeeded"
MSG3="(keepalived1) Entering MASTER STATE"
cat ./test-1-1.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}" || RETURN_VALUE=1

MSG1="(keepalived2) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) succeeded"
cat ./test-1-2.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}" || RETURN_VALUE=1

docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
echo "Test case 1 finished"
if [ "$RETURN_VALUE" -eq "0" ]; then
  echo "Test case 1 passed"
else
  echo "Test case 1 failed"
fi
RETURN_VALUES="$RETURN_VALUES $RETURN_VALUE"

echo "Starting test case 2: 01-OK 02-NOK"
RETURN_VALUE=0
docker run -d --name ${TEST_PREFIX}-1 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/true" \
    -e KEEPALIVED_SRC_IP=${TEST_IP1}\
    -e KEEPALIVED_PEER_IP=${TEST_IP2}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-01\
    -e KEEPALIVED_INSTANCE_NAME=keepalived1\
    -e KEEPALIVED_PRIORITY=150\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
docker run -d --name ${TEST_PREFIX}-2 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/false" \
    -e KEEPALIVED_SRC_IP=${TEST_IP2}\
    -e KEEPALIVED_PEER_IP=${TEST_IP1}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-02\
    -e KEEPALIVED_INSTANCE_NAME=keepalived2\
    -e KEEPALIVED_PRIORITY=145\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
sleep 10
docker logs ${TEST_PREFIX}-1 > ./test-2-1.log 2>&1
docker logs ${TEST_PREFIX}-2 > ./test-2-2.log 2>&1

MSG1="(keepalived1) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) succeeded"
MSG3="(keepalived1) Entering MASTER STATE"
cat ./test-2-1.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}" || RETURN_VALUE=1

MSG1="(keepalived2) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) failed (exited with status 1)"
MSG3="(keepalived2) Changing effective priority from 145 to 135"
cat ./test-2-2.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}" || RETURN_VALUE=1

docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
echo "Test case 2 finished"
if [ "$RETURN_VALUE" -eq "0" ]; then
  echo "Test case 2 passed"
else
  echo "Test case 2 failed"
fi
RETURN_VALUES="$RETURN_VALUES $RETURN_VALUE"

echo "Starting test case 3: 01-NOK 02-OK"
RETURN_VALUE=0
docker run -d --name ${TEST_PREFIX}-1 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/false" \
    -e KEEPALIVED_SRC_IP=${TEST_IP1}\
    -e KEEPALIVED_PEER_IP=${TEST_IP2}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-01\
    -e KEEPALIVED_INSTANCE_NAME=keepalived1\
    -e KEEPALIVED_PRIORITY=150\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
docker run -d --name ${TEST_PREFIX}-2 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/true" \
    -e KEEPALIVED_SRC_IP=${TEST_IP2}\
    -e KEEPALIVED_PEER_IP=${TEST_IP1}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-02\
    -e KEEPALIVED_INSTANCE_NAME=keepalived2\
    -e KEEPALIVED_PRIORITY=145\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
sleep 10
docker logs ${TEST_PREFIX}-1 > ./test-3-1.log 2>&1
docker logs ${TEST_PREFIX}-2 > ./test-3-2.log 2>&1

MSG1="(keepalived1) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) failed (exited with status 1)"
MSG3="(keepalived1) Entering BACKUP STATE"
cat ./test-3-1.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}" || RETURN_VALUE=1

MSG1="(keepalived2) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) succeeded"
MSG3="(keepalived2) received lower priority (140) advert from ${TEST_IP1} - discarding"
MSG4="(keepalived2) Entering MASTER STATE"
cat ./test-3-2.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}.*${MSG4}" || RETURN_VALUE=1

docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
echo "Test case 3 finished"
if [ "$RETURN_VALUE" -eq "0" ]; then
  echo "Test case 3 passed"
else
  echo "Test case 3 failed"
fi
RETURN_VALUES="$RETURN_VALUES $RETURN_VALUE"

echo "Starting test case 4: 01-NOK 02-NOK"
RETURN_VALUE=0
docker run -d --name ${TEST_PREFIX}-1 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/false" \
    -e KEEPALIVED_SRC_IP=${TEST_IP1}\
    -e KEEPALIVED_PEER_IP=${TEST_IP2}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-01\
    -e KEEPALIVED_INSTANCE_NAME=keepalived1\
    -e KEEPALIVED_PRIORITY=150\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
docker run -d --name ${TEST_PREFIX}-2 --cap-add NET_ADMIN --security-opt no-new-privileges:true --net ${TEST_PREFIX}-net --env-file ./example/env \
    -e KEEPALIVED_CHECK_SCRIPT="/bin/false" \
    -e KEEPALIVED_SRC_IP=${TEST_IP2}\
    -e KEEPALIVED_PEER_IP=${TEST_IP1}\
    -e KEEPALIVED_VIRTUAL_IP=${TEST_VIP}\
    -e KEEPALIVED_ROUTER_ID=keepalived-02\
    -e KEEPALIVED_INSTANCE_NAME=keepalived2\
    -e KEEPALIVED_PRIORITY=145\
    -e  KEEPALIVED_CHECK_INTERVAL=1\
    ${IMAGE_NAME}:${IMAGE_TAG}-${ARCH}
sleep 10
docker logs ${TEST_PREFIX}-1 > ./test-4-1.log 2>&1
docker logs ${TEST_PREFIX}-2 > ./test-4-2.log 2>&1

MSG1="(keepalived1) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) failed (exited with status 1)"
MSG3="(keepalived1) Changing effective priority from 150 to 140"
MSG4="(keepalived1) Entering MASTER STATE"
cat ./test-4-1.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}.*${MSG4}" || RETURN_VALUE=1

MSG1="(keepalived2) Entering BACKUP STATE (init)"
MSG2="VRRP_Script(check_status) failed (exited with status 1)"
MSG3="(keepalived2) Changing effective priority from 145 to 135"
cat ./test-4-2.log | tr '\n' '\a' | grep -o "${MSG1}.*${MSG2}.*${MSG3}" || RETURN_VALUE=1

docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
echo "Test case 4 finished"
if [ "$RETURN_VALUE" -eq "0" ]; then
  echo "Test case 4 passed"
else
  echo "Test case 4 failed"
fi
RETURN_VALUES="$RETURN_VALUES $RETURN_VALUE"

echo "All tests finished - cleaning up"
docker rm -f $(docker ps -f name=${TEST_PREFIX}* -q) || true
docker network rm -f ${TEST_PREFIX}-net || true

FAILED=0
for return_value in $RETURN_VALUES; do
  if [ "$return_value" -eq "1" ]; then
    FAILED=1
  fi
done
if [ "$FAILED" -eq "1" ]; then
  echo "Failures were found"
else
  echo "All tests passed"
fi
exit $FAILED
