#!/bin/bash
# Initialize vagrant boxes
vagrant up
# Create SSH tunnel for Kubernetes Dashboard
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy
ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1
# In a master node session Run kubectl proxy for DashBoard connection on localhost
kubectl proxy &
# Create SSH tunnel for ArgoCD Server
ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1
#In a master node session run port-forward for ArgoCD service
# https://localhost:8081/settings/repos
kubectl port-forward svc/argocd-server -n argocd 8081:443
# Install if not already the MediaWiki HELM App
helm install mediawiki /vagrant/helm/mediawiki/ -n mediawiki
# Create SSH tunnel to connect to MediaWiki
# http://localhost:8080/wiki
ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1