.DEFAULT_GOAL := up

CLUSTER_NAME ?= kind-cicd
KIND_CONFIG ?= 02-cluster.yaml
HOSTS_SCRIPT ?= 03-hosts.sh
METALLB_MANIFEST_URL ?= https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-frr-k8s.yaml
METALLB_CONFIG_FILE ?= 05-setup-metallb.yaml
HELMFILE_FILE ?= 06-helmfile.yaml

.PHONY: up pre inotify cluster hosts metallb metallb-config helmfile-apply helmfile-destroy down status

up: pre

pre: inotify cluster hosts metallb metallb-config helmfile-apply

inotify:
	@echo "Installing inotify limits..."
	@bash 01-inotify.sh

cluster:
	@echo "Ensuring kind cluster '$(CLUSTER_NAME)' exists..."
	@if kind get clusters | grep -qx "$(CLUSTER_NAME)"; then \
		echo "Cluster $(CLUSTER_NAME) already exists. Skipping create."; \
	else \
		kind create cluster --name "$(CLUSTER_NAME)" --config "$(KIND_CONFIG)"; \
	fi
	@kubectl config use-context "kind-$(CLUSTER_NAME)" >/dev/null

hosts:
	@echo "Updating /etc/hosts in worker containers for cluster $(CLUSTER_NAME)..."
	@bash "$(HOSTS_SCRIPT)" "$(CLUSTER_NAME)"

metallb:
	@echo "Applying MetalLB manifests..."
	@kubectl apply -f "$(METALLB_MANIFEST_URL)"
	@kubectl wait --namespace metallb-system \
		--for=condition=ready pod \
		--selector=app=metallb \
		--timeout=120s

metallb-config:
	@echo "Applying MetalLB address pool config from $(METALLB_CONFIG_FILE)..."
	@kubectl apply -f "$(METALLB_CONFIG_FILE)"

helmfile-apply:
	@echo "Applying platform releases via Helmfile $(HELMFILE_FILE)..."
	@helmfile -f "$(HELMFILE_FILE)" apply

helmfile-destroy:
	@echo "Destroying platform releases via Helmfile $(HELMFILE_FILE)..."
	@helmfile -f "$(HELMFILE_FILE)" destroy

down:
	@echo "Destroying Helm releases before deleting cluster $(CLUSTER_NAME)..."
	@if kind get clusters | grep -qx "$(CLUSTER_NAME)"; then \
		kubectl config use-context "kind-$(CLUSTER_NAME)" >/dev/null; \
		$(MAKE) helmfile-destroy; \
	else \
		echo "Cluster $(CLUSTER_NAME) not found. Skipping Helmfile destroy."; \
	fi
	@echo "Deleting kind cluster $(CLUSTER_NAME) if it exists..."
	@if kind get clusters | grep -qx "$(CLUSTER_NAME)"; then \
		kind delete cluster --name "$(CLUSTER_NAME)"; \
	else \
		echo "Cluster $(CLUSTER_NAME) not found. Nothing to delete."; \
	fi

status:
	@kind get clusters