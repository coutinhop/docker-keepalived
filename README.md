# docker-keepalived

Container for running [keepalived](https://github.com/acassen/keepalived), based on [alpine linux](https://hub.docker.com/_/alpine). Mainly used to achieve HA (high availability) for [pihole on docker](https://github.com/chriscrowe/docker-pihole-unbound). No relation to [osixia/docker-keepalived](https://github.com/osixia/docker-keepalived), other than sharing name and overall objective (in fact, this was created due to the existing repo not seeming active and/or up to date).

## Building

Build current system's architecture locally:
```
make build
```

Build all architectures locally (supported arches: amd64, arm64, arm):
```
make build-all
```

Push multi-arch manifest:
```
IMAGE_NAME=myusername/docker-keepalived make manifest
```

Test:
```
make test
```

Clean:
```
make clean
```

## Running

See redundant pihole docker compose examples in `example/` (to be run on 2 different nodes/machines), or run directly with `docker run`:
```
export KEEPALIVED_PASSWORD=mypassword
export KEPALIVED_NOTIFICATION_URL="https://ntfy.example.com/keepalived/publish?title=keepalived&auth=XXXX"
docker run -d --net host --name keepalived -h keepalived --cap-add NET_ADMIN --security-opt no-new-privileges:true --restart unless-stopped \
    -e TZ=${TZ:-UTC} \
    -e KEEPALIVED_NOTIFICATION_URL=${KEEPALIVED_NOTIFICATION_URL} \
    -e KEEPALIVED_PASSWORD=${KEEPALIVED_PASSWORD} \
    -e KEEPALIVED_ROUTER_ID=keepalived-01 \
    -e KEEPALIVED_WEIGHT=-10 \
    -e KEEPALIVED_INSTANCE_NAME=keepalived1 \
    -e KEEPALIVED_INTERFACE=eth0 \
    -e KEEPALIVED_VIRTUAL_ROUTER_ID=100 \
    -e KEEPALIVED_PRIORITY=150 \
    -e KEEPALIVED_SRC_IP=192.168.0.1 \
    -e KEEPALIVED_PEER_IP=192.168.0.2 \
    -e KEEPALIVED_VIRTUAL_IP=192.168.0.3/24 \
    -e KEEPALIVED_CHECK_SCRIPT="/usr/bin/curl -fsSL 127.0.0.1 || exit 1" \
    -e KEEPALIVED_CHECK_INTERVAL=5 \
    ghcr.io/coutinhop/docker-keepalived:latest
```

Configure weights and prioritys appropriately (the examples have a difference of 5 between primary and secondary and a weight of -10, achieving takeover of secondary if primary's check script fails).

Add `-v keepalived.conf.tpl:/etc/keepalived_templates/keepalived.conf.tpl:ro` (or the equivalent in docker compose) to override the image's config template with your own if needed.

## License

Apache 2.0. See the LICENSE file for more info.

