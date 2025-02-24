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

# default values for vars
export KEEPALIVED_ROUTER_ID=${KEEPALIVED_ROUTER_ID:=keepalived-01}
export KEEPALIVED_CHECK_INTERVAL=${KEEPALIVED_CHECK_INTERVAL:=5}
export KEEPALIVED_WEIGHT=${KEEPALIVED_WEIGHT:=-10}
export KEEPALIVED_INSTANCE_NAME=${KEEPALIVED_INSTANCE_NAME:=keepalived1}
export KEEPALIVED_INTERFACE=${KEEPALIVED_INTERFACE:=eth0}
export KEEPALIVED_VIRTUAL_ROUTER_ID=${KEEPALIVED_VIRTUAL_ROUTER_ID:=100}
export KEEPALIVED_PRIORITY=${KEEPALIVED_PRIORITY:=150}
export KEEPALIVED_PASSWORD=${KEEPALIVED_PASSWORD:=mypassword}
export KEEPALIVED_SRC_IP=${KEEPALIVED_SRC_IP:=192.168.0.1}
export KEEPALIVED_PEER_IP=${KEEPALIVED_PEER_IP:=192.168.0.2}
export KEEPALIVED_VIRTUAL_IP=${KEEPALIVED_VIRTUAL_IP:=192.168.0.3/24}
export KEEPALIVED_NOTIFICATION_URL=${KEEPALIVED_NOTIFICATION_URL:=https://ntfy.example.com/keepalived/publish?title=keepalived&auth=XXXX}
export KEEPALIVED_FLAGS=${KEEPALIVED_FLAGS:="-n -l"}

export KEEPALIVED_CHECK_SCRIPT=${KEEPALIVED_CHECK_SCRIPT:="/usr/bin/curl -fsSL 127.0.0.1 || exit 1"}

cat /etc/keepalived_templates/keepalived-check.sh.tpl | envsubst > /usr/bin/keepalived-check.sh
chmod +x /usr/bin/keepalived-check.sh

cat /etc/keepalived_templates/keepalived.conf.tpl | envsubst > /etc/keepalived/keepalived.conf

keepalived ${KEEPALIVED_FLAGS}
