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

FROM alpine:latest

RUN apk --no-cache add \
        bash \
        bind-tools \
        curl \
        envsubst \
        keepalived \
        tzdata

COPY keepalived-notify.sh /usr/bin/keepalived-notify.sh
RUN chmod +x /usr/bin/keepalived-notify.sh

COPY keepalived-init.sh /usr/bin/keepalived-init.sh
RUN chmod +x /usr/bin/keepalived-init.sh

COPY keepalived.conf.tpl /etc/keepalived_templates/keepalived.conf.tpl
COPY keepalived-check.sh.tpl /etc/keepalived_templates/keepalived-check.sh.tpl

RUN mkdir -p /etc/keepalived

CMD ["keepalived-init.sh"]
