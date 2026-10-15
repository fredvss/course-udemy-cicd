#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${1:-kind-cicd}"
HOSTS_ENTRY="172.22.0.50 argocd.localhost.com jenkins.localhost.com gitea.localhost.com sonarqube.localhost.com harbor.localhost.com"

worker_containers=$(docker ps \
	--filter "label=io.x-k8s.kind.role=worker" \
	--filter "label=io.x-k8s.kind.cluster=${CLUSTER_NAME}" \
	-q)

if [[ -z "$worker_containers" ]]; then
	echo "No worker containers found for cluster '${CLUSTER_NAME}'."
	exit 0
fi

for container in $worker_containers; do
	docker exec "$container" sh -c "grep -Fqx '$HOSTS_ENTRY' /etc/hosts || echo '$HOSTS_ENTRY' >> /etc/hosts"
done

echo "Ensured /etc/hosts entry in all worker containers for cluster '${CLUSTER_NAME}'."