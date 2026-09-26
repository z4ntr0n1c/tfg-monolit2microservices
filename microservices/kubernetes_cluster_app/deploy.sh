#!/bin/bash
# =============================================================================
# deploy.sh — Monolit2Microservices cluster helper
# =============================================================================
# All commands assume you are on the HOST machine (not inside the VM).
# SSH tunnels must be opened in separate terminal tabs/windows.
# =============================================================================

set -euo pipefail

# ── 1. Boot the Vagrant cluster (master + worker1 + worker2) ─────────────────
# Provisions Kubernetes 1.20, Flannel CNI, metrics-server, Kubernetes Dashboard,
# Helm, HashiCorp Vault (dev mode) and the MediaWiki Helm release automatically.
vagrant up

# ── 2. Kubernetes Dashboard ───────────────────────────────────────────────────
# Open a tunnel (separate terminal):
#   ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1
# Inside the master node, run:
#   kubectl proxy &
# Access: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy
# Token: printed at the end of vagrant up provisioning output.

# ── 3. ArgoCD ─────────────────────────────────────────────────────────────────
# Open a tunnel (separate terminal):
#   ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1
# Inside the master node, run:
#   kubectl port-forward svc/argocd-server -n argocd 8081:443
# Access: https://localhost:8081/settings/repos

# ── 4. Vault UI (dev mode — token: root) ─────────────────────────────────────
# Open a tunnel (separate terminal):
#   ssh -L 8200:localhost:8200 -p 2222 vagrant@127.0.0.1
# Inside the master node, run:
#   kubectl port-forward -n vault svc/vault 8200:8200
# Access: http://localhost:8200  |  Token: root

# ── 5. MediaWiki ─────────────────────────────────────────────────────────────
# Installed automatically by vagrant up via Helm.
# To reinstall manually (inside master node):
#   helm install mediawiki /vagrant/helm/mediawiki --create-namespace --namespace mediawiki
#
# Open a tunnel (separate terminal):
#   ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1
# Access: http://localhost:8080/wiki

# ── 6. Useful one-liners (run inside master node) ─────────────────────────────
# Check all pods across namespaces:
#   kubectl get pods -A
#
# Check Vault secrets are being injected (replace <pod> with actual pod name):
#   kubectl exec -n mediawiki <pod> -c php -- cat /vault/secrets/db.env
#
# Read a Vault secret directly:
#   kubectl exec -n vault vault-0 -- vault kv get secret/mediawiki/mysql
#
# Verify Vault Kubernetes auth role:
#   kubectl exec -n vault vault-0 -- vault read auth/kubernetes/role/mediawiki
