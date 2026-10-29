#!/usr/bin/env bash
set -euo pipefail
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/crewmeister-admin.conf}"
export KUBECONFIG
kubectl get nodes -o wide
kubectl -n crewmeister get secret crewmeister-db -o name >/dev/null
kubectl -n crewmeister get deployment,sts,svc,pvc,pods -o wide
kubectl -n argocd get applications.argoproj.io crewmeister-local
kubectl -n crewmeister rollout status deployment/crewmeister-app --timeout=300s
kubectl -n crewmeister rollout status statefulset/crewmeister-mysql --timeout=300s
