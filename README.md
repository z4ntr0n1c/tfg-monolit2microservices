# Monolit2Microservices

> **TFG — Migració d'Arquitectura Monolítica a Microserveis**
>
> Sergio Santamaria Bayés

Migration of a traditional monolithic MediaWiki application to a microservices-based architecture running on Kubernetes, incorporating DevOps/GitOps practices, container orchestration, dynamic scaling, and secrets management with HashiCorp Vault.

OpenAccess UOC Repository: https://openaccess.uoc.edu/items/2834c970-e97c-4f4d-9fd3-c13cbf6cb7b3#page=1

---

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Service Access](#service-access)
- [Secrets Management (Vault)](#secrets-management-vault)
- [Helm Chart Details](#helm-chart-details)
- [Useful Commands](#useful-commands)
- [Documentation](#documentation)

---

## Project Overview

This project documents and implements the end-to-end migration of a monolithic LAMP+MediaWiki application into a microservices architecture. The key objectives are:

- **Decomposition** — Split the monolith into independent Apache, PHP-FPM and MySQL microservices.
- **Orchestration** — Deploy and manage the services on a multi-node Kubernetes cluster.
- **Infrastructure as Code** — Automate cluster provisioning with Vagrant and application deployment with Helm charts.
- **Secrets Management** — Centralise all sensitive credentials in HashiCorp Vault with automatic injection into pods at runtime.
- **Autoscaling** — Horizontal Pod Autoscaler (HPA) based on CPU and memory utilisation.
- **GitOps** — ArgoCD for declarative, Git-driven continuous delivery.
- **Observability** — Kubernetes Dashboard and metrics-server for cluster monitoring.

---

## Repository Structure

```
Project/
├── README.md                          ← You are here
├── doc/                               ← TFG thesis documents, diagrams, Gantt chart
├── monolit/                           ← Original monolithic application
│   ├── app/                           ← MediaWiki LocalSettings + DB dump
│   └── lamp/                          ← Docker/Vagrant setup scripts
└── microservices/
    └── kubernetes_cluster_app/        ← ★ Kubernetes microservices stack
        ├── Vagrantfile                ← Cluster provisioning (master + 2 workers)
        ├── deploy.sh                  ← Deployment & access reference script
        ├── kubernetes-dashboard.yaml  ← Dashboard manifests
        ├── nginx-ingress-v0.44.0.yaml ← NGINX Ingress controller
        ├── data/php/mediawiki/        ← MediaWiki data (LocalSettings.php, images)
        └── helm/
            ├── get_helm.sh            ← Helm installer script
            ├── mediawiki/             ← Helm chart — MediaWiki stack
            │   ├── Chart.yaml
            │   ├── values.yaml
            │   ├── Dockerfile
            │   └── templates/
            │       ├── deployment.yaml       ← Apache, MySQL, PHP deployments
            │       ├── serviceaccount.yaml    ← SA for Vault auth
            │       ├── secrets.yaml           ← (replaced by Vault)
            │       ├── configmap.yaml
            │       ├── service.yaml
            │       ├── storage.yaml
            │       ├── ingress.yaml
            │       └── hpa.yaml
            └── lamp/                  ← Helm chart — generic LAMP stack
```

---

## Architecture

```
                         ┌──────────────────────────────────────────┐
                         │           VirtualBox / Vagrant           │
                         │                                          │
  ┌───────────┐   ┌──────┴──────┐   ┌───────────┐   ┌───────────┐ │
  │  Host     │   │   master    │   │  worker1  │   │  worker2  │ │
  │  machine  │──▶│ 10.0.0.10   │──▶│ 10.0.0.11 │   │ 10.0.0.12 │ │
  │           │   │ (2 vCPU)    │   │ (1 vCPU)  │   │ (1 vCPU)  │ │
  └───────────┘   └──────┬──────┘   └───────────┘   └───────────┘ │
                         └──────────────────────────────────────────┘
                                │
                    Kubernetes 1.20 (kubeadm)
                    Flannel CNI  │  metrics-server
                                │
          ┌─────────────────────┼───────────────────────┐
          │                     │                       │
   vault namespace       mediawiki namespace      argocd namespace
   ┌──────────────┐    ┌──────────────────────┐   ┌──────────────┐
   │ Vault (dev)  │    │  Apache   PHP   MySQL│   │  ArgoCD      │
   │ + Injector   │──▶│  (secrets injected   │   │  Server      │
   │              │    │   by Vault Agent)    │   │              │
   └──────────────┘    └──────────────────────┘   └──────────────┘
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Virtualisation | Vagrant + VirtualBox |
| Container Runtime | Docker |
| Orchestration | Kubernetes 1.20 (kubeadm) |
| Networking | Flannel CNI + NGINX Ingress |
| Package Manager | Helm 3 |
| Secrets | HashiCorp Vault (dev mode, KV-v2) |
| GitOps | ArgoCD |
| Monitoring | Kubernetes Dashboard + metrics-server |
| Application | MediaWiki (Apache + PHP-FPM + MySQL 5.7) |
| Scaling | Horizontal Pod Autoscaler (HPA) |

---

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/) ≥ 6.1
- [Vagrant](https://www.vagrantup.com/) ≥ 2.2
- At least **8 GB of free RAM** (the cluster allocates 2 GB × 3 VMs)
- Internet access during first provisioning (downloads box images, Helm charts, container images)

---

## Quick Start

```bash
# 1. Clone the repository
git clone <repo-url> && cd Project/microservices/kubernetes_cluster_app

# 2. Start the cluster (provisions everything automatically)
vagrant up

# 3. SSH into the master node
vagrant ssh master

# 4. Verify all pods are running
kubectl get pods -A
```

The `vagrant up` command automatically provisions:

1. Kubernetes cluster (kubeadm init + worker joins)
2. Flannel CNI + metrics-server
3. Kubernetes Dashboard
4. Helm 3
5. HashiCorp Vault in dev mode (+ Kubernetes auth, seeded secrets, policies)
6. MediaWiki Helm release in the `mediawiki` namespace

See [`deploy.sh`](microservices/kubernetes_cluster_app/deploy.sh) for the full reference of tunnels and access URLs.

---

## Service Access

All services run inside the VMs. Use SSH tunnels from your host machine to access them.

| Service | Tunnel Command (host terminal) | Port-forward (inside master) | URL |
|---|---|---|---|
| **Kubernetes Dashboard** | `ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1` | `kubectl proxy &` | http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy |
| **ArgoCD** | `ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward svc/argocd-server -n argocd 8081:443` | https://localhost:8081 |
| **Vault UI** | `ssh -L 8200:localhost:8200 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward -n vault svc/vault 8200:8200` | http://localhost:8200 (token: `root`) |
| **MediaWiki** | `ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1` | — (NodePort) | http://localhost:8080/wiki |

---

## Secrets Management (Vault)

All sensitive credentials are stored in **HashiCorp Vault** (dev mode, KV-v2 engine) and injected into pods at runtime by the **Vault Agent Injector** sidecar. No secrets are stored in `values.yaml`, Kubernetes Secret objects, or source code.

### How it works

1. Vault runs in the `vault` namespace with the **Kubernetes auth backend** enabled.
2. Pods use the `mediawiki-sa` ServiceAccount to authenticate with Vault.
3. Vault Agent annotations on the pod templates tell the injector which secrets to fetch and how to render them.
4. The injector writes secrets as env-sourceable files to `/vault/secrets/` inside the pod.
5. Containers source these files before starting their main process.

### Vault paths

| Path | Keys |
|---|---|
| `secret/mediawiki/mysql` | `root_password`, `database`, `user`, `password` |
| `secret/mediawiki/app` | `secret_key` (MediaWiki `$wgSecretKey`), `upgrade_key` (`$wgUpgradeKey`) |

### Managing secrets

```bash
# SSH into master node, then:

# List secrets
kubectl exec -n vault vault-0 -- vault kv get secret/mediawiki/mysql

# Update a secret
kubectl exec -n vault vault-0 -- vault kv put secret/mediawiki/mysql \
  root_password="NewP@ssw0rd" \
  database="wikidb" \
  user="wikiuser" \
  password="NewUserP@ss"

# Restart pods to pick up new secrets
kubectl rollout restart deployment -n mediawiki
```

> **Note:** Vault is running in **dev mode** — all data is stored in memory and will be lost if the Vault pod restarts. This is appropriate for a lab/TFG context. For production, use standalone mode with persistent storage.

---

## Helm Chart Details

The **mediawiki** Helm chart (`helm/mediawiki/`) deploys three microservices:

| Component | Image | Port | Description |
|---|---|---|---|
| **Apache** | `httpd:latest` | 80 (NodePort 30080) | Reverse proxy / web server |
| **PHP-FPM** | `mediawiki:latest` | 80 | PHP application processor |
| **MySQL** | `mysql:5.7` | 3306 | Database server |

### Key templates

| Template | Purpose |
|---|---|
| `deployment.yaml` | 3 Deployments (Apache, MySQL, PHP) with Vault Agent annotations |
| `serviceaccount.yaml` | `mediawiki-sa` — identity for Vault Kubernetes auth |
| `service.yaml` | ClusterIP and NodePort services |
| `configmap.yaml` | Apache httpd.conf, MySQL my.cnf, PHP-FPM www.conf |
| `storage.yaml` | PersistentVolumeClaims for MySQL data and MediaWiki images |
| `hpa.yaml` | HorizontalPodAutoscaler (1–5 replicas, 80% CPU/memory target) |
| `ingress.yaml` | NGINX Ingress rules |

### Install / upgrade

```bash
# Inside the master node
helm install mediawiki /vagrant/helm/mediawiki --create-namespace --namespace mediawiki

# Upgrade after chart changes
helm upgrade mediawiki /vagrant/helm/mediawiki -n mediawiki
```

---

## Useful Commands

```bash
# Cluster status
kubectl get nodes
kubectl get pods -A

# MediaWiki logs
kubectl logs -n mediawiki -l component=php -c php
kubectl logs -n mediawiki -l component=mysql -c mysql

# Verify Vault injection
kubectl exec -n mediawiki <pod-name> -c php -- cat /vault/secrets/db.env

# HPA status
kubectl get hpa -n mediawiki

# Vault health
kubectl exec -n vault vault-0 -- vault status

# Destroy and recreate cluster
vagrant destroy -f && vagrant up
```

---

## Documentation

The `doc/` directory contains the full TFG thesis and supporting materials:

- **TFG thesis** (PDF) — Complete migration analysis and methodology
- **Annexes** (PDF) — Additional technical documentation
- **Architecture diagrams** — Monolithic vs. microservices functional groupings, CI/CD pipeline
- **Gantt chart** — Project timeline and phases
