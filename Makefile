OPM=bin/opm
OPM_VERSION=v1.14.2

CONFTEST=bin/conftest
CONFTEST_VERSION=v0.21.0

YQ=bin/yq
YQ_VERSION=3.4.0

ARCH=amd64

PROJECT_DIR=$(shell pwd)

# Variables for building bundle image.
BUNDLE_VERSION ?=
PACKAGE_NAME ?= storageos2
BUNDLE_IMAGE_NAME ?= storageos/operator-bundle
BUNDLE_IMAGE ?= $(BUNDLE_IMAGE_NAME):v$(BUNDLE_VERSION)
BUNDLE_DOCKERFILE ?= bundle-$(BUNDLE_VERSION).Dockerfile

# Variables for building index image.
INDEX_BUNDLES ?=
INDEX_VERSION ?= test
INDEX_IMAGE_NAME ?= storageos/operator-index
INDEX_IMAGE ?= $(INDEX_IMAGE_NAME):$(INDEX_VERSION)
CONTAINER_TOOL ?= docker

# Variables for olm-bundle generation.
OLM_BUNDLE_ACTION_VERSION ?= v0.2.0
OLM_BUNDLE_ACTION_IMAGE ?= ghcr.io/darkowlzz/olm-bundle:$(OLM_BUNDLE_ACTION_VERSION)
OLM_BUNDLE_ACTION_WORKSPACE ?= /github/workspace
CHANNELS ?= stable
DEFAULT_CHANNEL ?= stable
OPERATOR_REPO ?= https://github.com/storageos/cluster-operator
OPERATOR_BRANCH ?= master
OPERATOR_MANIFESTS_DIR ?= bundle/manifests
DOCKERFILE_LABELS_FILE ?= storageos2/common-labels.txt

# Variables for updating related images.
RELATED_IMAGE_UPDATE_VERSION ?= v0.2.0
RELATED_IMAGE_UPDATE_IMAGE ?= ghcr.io/darkowlzz/related-image-update:$(RELATED_IMAGE_UPDATE_VERSION)
CSV_PATH=manifests/storageosoperator.clusterserviceversion.yaml
TARGET_DEPLOYMENT_NAME=storageos-operator
TARGET_CONTAINER_NAME=storageos-operator

# The help will print out all targets with their descriptions organized bellow their categories. The categories are represented by `##@` and the target descriptions by `##`.
# The awk commands is responsable to read the entire set of makefiles included in this invocation, looking for lines of the file as xyz: ## something, and then pretty-format the target and help. Then, if there's a line with ##@ something, that gets pretty-printed as a category.
# More info over the usage of ANSI control characters for terminal formatting: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info over awk command: http://linuxcommand.org/lc3_adv_awk.php
.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""


##@ Build
bundle-build: ## Build bundle image (BUNDLE_VERSION required)
# TODO: Make PACKAGE_NAME required when multiple bundles are added. Since
# there's only one bundle, check for BUNDLE_VERSION only for now.
ifeq ($(BUNDLE_VERSION),)
	$(error BUNDLE_VERSION is a required argument)
endif
	cd $(PACKAGE_NAME); \
	$(CONTAINER_TOOL) build -f $(BUNDLE_DOCKERFILE) -t $(BUNDLE_IMAGE) .

index-build: opm ## Build index image (INDEX_BUNDLES required)
ifeq ($(INDEX_BUNDLES),)
	$(error INDEX_BUNDLES is a required argument)
endif
	$(OPM) index add --bundles $(INDEX_BUNDLES) \
		--tag $(INDEX_IMAGE) \
		-c $(CONTAINER_TOOL)

generate-bundle: ## Generate new versioned bundle (BUNDLE_VERSION required)
# TODO: Make PACKAGE_NAME required when multiple bundles are added. Since
# there's only one bundle, check for BUNDLE_VERSION only for now.
ifeq ($(BUNDLE_VERSION),)
	$(error BUNDLE_VERSION is a required argument)
endif
	$(CONTAINER_TOOL) run --rm \
		-v $(shell pwd):$(OLM_BUNDLE_ACTION_WORKSPACE) \
		-e OUTPUT_DIR=$(PACKAGE_NAME)/$(BUNDLE_VERSION) \
		-e CHANNELS=$(CHANNELS) \
		-e DEFAULT_CHANNEL=$(DEFAULT_CHANNEL) \
		-e PACKAGE=$(PACKAGE_NAME) \
		-e OPERATOR_REPO=$(OPERATOR_REPO) \
		-e OPERATOR_BRANCH=$(OPERATOR_BRANCH) \
		-e OPERATOR_MANIFESTS_DIR=$(OPERATOR_MANIFESTS_DIR) \
		-e DOCKERFILE_LABELS_FILE=$(DOCKERFILE_LABELS_FILE) \
		-u "$(shell id -u):$(shell id -g)" \
		$(OLM_BUNDLE_ACTION_IMAGE)

related-images: ## Update related images in a bundle (BUNDLE_VERSION required)
ifeq ($(BUNDLE_VERSION),)
	$(error BUNDLE_VERSION is a required argument)
endif
	$(CONTAINER_TOOL) run --rm \
		-v $(shell pwd):$(OLM_BUNDLE_ACTION_WORKSPACE) \
		-e IMAGE_LIST_FILE=$(PACKAGE_NAME)/imagelist-$(BUNDLE_VERSION).yaml \
		-e TARGET_FILE=$(PACKAGE_NAME)/$(BUNDLE_VERSION)/$(CSV_PATH) \
		-e TARGET_DEPLOYMENT_NAME=$(TARGET_DEPLOYMENT_NAME) \
		-e TARGET_CONTAINER_NAME=$(TARGET_CONTAINER_NAME) \
		-u "$(shell id -u):$(shell id -g)" \
		$(RELATED_IMAGE_UPDATE_IMAGE)

##@ Test
opm-validate: opm ## Run opm validate on a bundle (BUNDLE_IMAGE required)
ifeq ($(BUNDLE_IMAGE),)
	$(error BUNDLE_IMAGE is a required argument)
endif
	$(OPM) alpha bundle validate -t $(BUNDLE_IMAGE)

conftest-validate: conftest ## Validate a bundle against repo policy (BUNDLE_VERSION required)
ifeq ($(BUNDLE_VERSION),)
	$(error BUNDLE_VERSION is a required argument)
endif
	$(CONFTEST) test $(PACKAGE_NAME)/$(BUNDLE_VERSION)/$(CSV_PATH) -o table

##@ Tools
opm: ## Install opm.
	@mkdir -p bin
	@if [ ! -f $(OPM) ]; then \
		curl -Lo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/linux-${ARCH}-opm ;\
		chmod +x $(OPM) ;\
	fi

conftest: ## Install conftest
	@mkdir -p bin
	@if [ ! -f $(CONFTEST) ]; then \
		cd /tmp; \
		curl -Lo conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/${CONFTEST_VERSION}/conftest_0.21.0_Linux_x86_64.tar.gz; \
		tar zxvf conftest.tar.gz; \
		cp conftest $(PROJECT_DIR)/$(CONFTEST); \
	fi

yq: ## Install yq.
	mkdir -p bin
	@if [ ! -f $(YQ) ]; then \
		curl -Lo $(YQ) https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH} ;\
		chmod +x $(YQ) ;\
	fi
