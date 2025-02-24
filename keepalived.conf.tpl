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

global_defs {
	router_id $KEEPALIVED_ROUTER_ID
	script_user root
	enable_script_security
}

vrrp_script check_status {
	script /usr/bin/keepalived-check.sh
	interval $KEEPALIVED_CHECK_INTERVAL
	weight $KEEPALIVED_WEIGHT
}

vrrp_instance $KEEPALIVED_INSTANCE_NAME {
    interface $KEEPALIVED_INTERFACE
    state BACKUP
    virtual_router_id $KEEPALIVED_VIRTUAL_ROUTER_ID
    priority $KEEPALIVED_PRIORITY
	advert_int 3
    authentication {
        auth_type PASS
        auth_pass $KEEPALIVED_PASSWORD
    }
	unicast_src_ip $KEEPALIVED_SRC_IP
	unicast_peer {
		$KEEPALIVED_PEER_IP
	}
    virtual_ipaddress {
        $KEEPALIVED_VIRTUAL_IP
    }
	track_script {
		check_status
	}
    notify "/usr/bin/keepalived-notify.sh $KEEPALIVED_NOTIFICATION_URL"
}
