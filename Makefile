OPM=bin/opm
OPM_VERSION=v1.14.2
ARCH=amd64

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
	docker build -f $(BUNDLE_DOCKERFILE) -t $(BUNDLE_IMAGE) .

index-build: opm ## Build index image (INDEX_BUNDLES required)
ifeq ($(INDEX_BUNDLES),)
	$(error INDEX_BUNDLES is a required argument)
endif
	$(OPM) index add --bundles $(INDEX_BUNDLES) \
		--tag $(INDEX_IMAGE) \
		-c $(CONTAINER_TOOL)

##@ Tools
opm: ## Install opm.
	@mkdir -p bin
	@if [ ! -f $(OPM) ]; then \
		curl -Lo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/linux-${ARCH}-opm ;\
		chmod +x $(OPM) ;\
	fi
