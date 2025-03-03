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

IMAGE_NAME ?= ghcr.io/coutinhop/docker-keepalived
IMAGE_TAG ?= latest
ARCHES ?= amd64 arm64 arm

IMAGE_MARKER = .docker-keepalived.created
PUSH_MARKER = .docker-keepalived.pushed

TEST_CONTAINER = docker-keepalived-test

ARCH ?= $(shell uname -m)
ARCH := $(subst aarch64,arm64,$(ARCH))
ARCH := $(subst x86_64,amd64,$(ARCH))
ARCH := $(subst armv7l,arm,$(ARCH))

SOURCE_FILES = Dockerfile keepalived-init.sh keepalived-notify.sh keepalived.conf.tpl Makefile

.PHONY: build
build: sub-build-$(ARCH)

.PHONY: build-all
build-all: $(addprefix sub-build-,$(ARCHES))

sub-build-%:
	$(MAKE) $(IMAGE_MARKER)-$*

$(IMAGE_MARKER)-%: $(SOURCE_FILES)
	docker buildx build --platform=linux/$* --pull --output=type=docker --tag $(IMAGE_NAME):$(IMAGE_TAG)-$* -f Dockerfile .
	touch $@

.PHONY: push-all
push-all: $(addprefix sub-push-,$(ARCHES))

sub-push-%:
	$(MAKE) $(PUSH_MARKER)-$*

$(PUSH_MARKER)-%:
	$(MAKE) $(IMAGE_MARKER)-$*
	docker push $(IMAGE_NAME):$(IMAGE_TAG)-$*
	touch $@

.PHONY: manifest
manifest: push-all
	docker manifest create $(IMAGE_NAME):$(IMAGE_TAG) $(addprefix --amend $(IMAGE_NAME):$(IMAGE_TAG)-,$(ARCHES))
	docker manifest push $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: test
test: build
	./test.sh

.PHONY: clean
clean:
	docker rm -f $(shell docker ps -f name=$(TEST_CONTAINER)* -q) || true
	docker network rm -f $(TEST_CONTAINER)-net || true
	docker rmi $(shell docker image ls -f reference=$(IMAGE_NAME) -q) || true
	rm -f $(IMAGE_MARKER)-*
	rm -f $(PUSH_MARKER)-*
	rm -f test-*.log
