SNAME ?= samba
RNAME ?= elswork/$(SNAME)
ONAME ?= deftwork/$(SNAME)
VER ?= `cat VERSION`
BASENAME ?= alpine:latest
TARGET_PLATFORM ?= linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7,linux/arm/v6
# linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7,linux/arm/v6
NO_CACHE ?= 
# NO_CACHE ?= --no-cache
#MODE ?= debug
MODE ?= $(VER)

# HELP
# This will output the help for each task

.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# DOCKER TASKS

# Build image

debug: ## Debug the container
	docker build -t $(RNAME):debug \
	--build-arg BASEIMAGE=$(BASENAME) \
	--build-arg VERSION=$(VER) .
build: ## Build the container
	mkdir -p builds
	docker build $(NO_CACHE) -t $(RNAME):$(VER) -t $(RNAME):latest \
	--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	--build-arg VCS_REF=`git rev-parse --short HEAD` \
	--build-arg BASEIMAGE=$(BASENAME) \
	--build-arg VERSION=$(VER) \
	. > builds/$(VER)_`date +"%Y%m%d_%H%M%S"`.txt
bootstrap: ## Start multicompiler
	docker buildx inspect --bootstrap
debugx: ## Buildx in Debug mode
	docker buildx build \
	--platform ${TARGET_PLATFORM} \
	-t $(RNAME):debug --pull \
	--build-arg BASEIMAGE=$(BASENAME) \
	--build-arg VERSION=$(VER) .
buildx: ## Buildx the container
	docker buildx build $(NO_CACHE) \
	--platform ${TARGET_PLATFORM} \
	-t ghcr.io/$(ONAME):$(VER) -t ghcr.io/$(ONAME):latest \
	-t $(RNAME):$(VER) -t $(RNAME):latest --pull --push \
	--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
	--build-arg VCS_REF=`git rev-parse --short HEAD` \
	--build-arg BASEIMAGE=$(BASENAME) \
	--build-arg VERSION=$(VER) .

# Operations

start: ## Start samba
	docker run -d -p 139:139 -p 445:445 -e TZ=Europe/Madrid \
	-v /home/pirate/docker/makefile:/share/folder $(RNAME):$(MODE) \
	-u "1000:1000:pirate:pirate:put-any-password-here" \
	-s "SmbShare:/share/folder:rw:pirate"
