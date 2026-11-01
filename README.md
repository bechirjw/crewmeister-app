<div align="center">

# DevSecOps & GitOps Platform

### Crewmeister — Secure, Automated Kubernetes Delivery

**From source code to a reviewed, observable Kubernetes release**

![Spring Boot](https://img.shields.io/badge/Spring_Boot-Application-6DB33F?logo=springboot&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose_%26_Images-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-On--Prem_%26_AKS-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure_as_Code-844FBA?logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-Cluster_Automation-EE0000?logo=ansible&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-DevSecOps_CI-2088FF?logo=githubactions&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo_CD-GitOps-EF7B4D?logo=argo&logoColor=white)

[Overview](#overview) · [Architecture](#architecture) · [Infrastructure](#on-premises-kubernetes-with-ansible) · [CI/CD](#github-actions--devsecops-pipeline) · [GitOps](#helm--argo-cd-gitops) · [Observability](#monitoring-logging--alerting) · [Testing](#application--api-testing)

</div>

---

## Overview

This project demonstrates an **end-to-end DevSecOps and GitOps workflow** for a Java Spring Boot application. It combines local development, automated Kubernetes infrastructure, security-aware CI, pull-request-controlled delivery, and operational monitoring.

**What the project covers**

| Area | Implementation approach | Value |
| --- | --- | --- |
| Local development | Docker and Docker Compose | Reproducible application environment |
| On-premises infrastructure | VMware, Ubuntu, Kubernetes, Ansible | Automated multi-node cluster provisioning |
| Cloud infrastructure | Terraform and Azure Kubernetes Service (AKS) | Reusable cloud infrastructure definition |
| Continuous integration | GitHub Actions, Maven, SonarQube Cloud, Gitleaks, Trivy | Automated builds, tests and security feedback |
| Continuous delivery | Pull requests, Helm, Argo CD | Review-gated, declarative deployments |
| Operations | Metrics, Grafana, Loki and alerting components | Visibility into workload health and failures |
| Persistent storage | Kubernetes PVCs and Local Path Provisioner | Storage lifecycle management in the local cluster |

> **Verification note:** This README describes the architecture and workstreams developed for the project. The exact enabled CI gates, cloud backend, current deployments, dashboards and alerts must be checked against the live repository and clusters before claiming production readiness. Evidence screenshots should show actual results, not illustrative statuses.

## Architecture

### 1. Application delivery workflow

![alt text](<DevOps GitOps Architecture Flow-1.png>)

**Important distinction:** CI creates and validates an artifact. A reviewed **GitOps configuration change** authorizes a release. Argo CD then synchronizes approved desired state with the target cluster. The configured branch rules and sync policy determine which steps are enforced automatically.

### 2. Infrastructure architecture

![alt text](<Hybrid Infrastructure & Application Delivery (1)-1.png>)
**Why two environments?** The VMware cluster demonstrates hands-on Kubernetes installation and operations; AKS demonstrates managed Kubernetes infrastructure as code. The same application packaging concepts can be reused while environment-specific settings remain separate.

---

## Docker & Docker Compose

The Spring Boot application is packaged with the root [`Dockerfile`](Dockerfile). [`compose.yaml`](compose.yaml) provides a local, repeatable way to start the services declared by the project without manually launching each container.

```bash
# Validate the Compose configuration without starting services
docker compose config --quiet

# Start the locally configured stack
docker compose up --build -d

docker compose ps
docker compose logs --tail=80
```

### Containerization best practices

| Practice | Benefit |
| --- | --- |
| Externalize passwords, tokens and connection settings | Avoids hardcoding secrets in source code or container images |
| Supply sensitive values through appropriate runtime secrets or environment configuration | Keeps deployment configuration separate from application code |
| Use `.gitignore` for local `.env` files containing secrets | Reduces accidental credential exposure |
| Use reproducible, versioned image builds | Makes releases traceable and easier to roll back |
| Define service health checks, restart behavior and resource constraints where applicable | Improves reliability and diagnostics |
| Keep local Compose configuration separate from Kubernetes deployment values | Prevents environment-specific assumptions from leaking into production |

**Secret handling:** Never commit real `.env` files, passwords, private keys or kubeconfigs. An `.env.example` may document required **variable names** with non-sensitive placeholders. CI credentials should be stored in the platform's protected secret store or supplied through a suitable identity mechanism.

---
![alt text](<Capture d'écran 2026-10-27 205018.png>)
## On-Premises Kubernetes with Ansible

The on-premises environment uses **Ubuntu virtual machines on VMware**. Ansible automates the repeatable Kubernetes setup through an inventory, playbooks, reusable roles and shared variables rather than a long sequence of manual SSH commands.

**Project location:** [`crewmeister-k8s-ansible/`](crewmeister-k8s-ansible/)

| File or directory | Purpose |
| --- | --- |
| `inventory.yml` | Defines the hosts and groups managed by Ansible |
| `ansible.cfg` | Centralizes Ansible execution settings |
| `site.yml` | Entry point for cluster automation |
| `preflight.yml` | Validates prerequisites before provisioning |
| `roles/` | Separates infrastructure tasks into reusable responsibilities |
| `group_vars/` | Stores shared, non-sensitive cluster configuration |
| `fetch-kubeconfig.yml` | Supports retrieval of Kubernetes client configuration |
| `reset-cluster.yml` | Provides a controlled cluster reset path; use only when intended |

### Role-based automation

The playbooks organize responsibilities such as **host preparation**, **container runtime and Kubernetes prerequisites**, **control-plane initialization**, **worker joining**, and **cluster networking/add-ons**. The precise tasks and role names are defined in `roles/` and `site.yml`; avoid treating this summary as a list of verified role names.

**Benefits:** repeatability, parameterized configuration, maintainability, easier troubleshooting, and the possibility of verifying idempotence across repeated runs.

```bash
cd crewmeister-k8s-ansible
ansible-inventory -i inventory.yml --graph
ansible-playbook -i inventory.yml site.yml --syntax-check
ansible-playbook -i inventory.yml site.yml --list-tasks
```
![alt text](<Capture d'écran 2026-10-27 154419.png>)
**Cluster verification** (using the on-premises kubeconfig already prepared in the WSL environment):

```bash
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get nodes -o wide

```
![alt text](<Capture d'écran 2026-11-01 111711.png>)


<!-- Add verified screenshot: docs/assets/infrastructure/onprem-cluster.png -->

---

## Azure AKS with Terraform

The cloud infrastructure workstream uses **Terraform** to describe Azure resources and **Azure Kubernetes Service (AKS)** through reusable configuration. The architecture separates a **system node pool** for cluster services from a **user node pool** intended for application workloads.

### Design decisions

- **Modules and variables:** infrastructure components can be reused and configured per environment.
- **System/user node pools:** separate platform responsibilities from application scheduling.
- **Infrastructure planning:** inspect proposed changes with `terraform plan` before applying them.
- **State management:** keep Terraform state outside source control and restrict access to it.

### Terraform backend and remote state

An **Azure Storage (`azurerm`) remote backend** is an appropriate backend design for team-managed AKS infrastructure: it centralizes state, supports state locking, and reduces reliance on local state files. **Verify whether the remote backend is configured in `terraform/` before describing it as deployed.** Backend configuration and credentials must not be committed as secrets.

```bash
cd terraform
terraform fmt -check -recursive
terraform init                  # Initializes the configured providers/backend
terraform validate
terraform plan                  # Review changes; requires valid Azure credentials
```

`terraform plan` reports intended changes; it does not prove that they were applied. The strongest AKS evidence is the actual resource and node-pool state:

```bash
kubectl --kubeconfig="$HOME/.kube/crewmeister-aks" get nodes -L agentpool
kubectl --kubeconfig="$HOME/.kube/crewmeister-aks" get pods -A -o wide
```
![alt text](<Capture d'écran 2026-11-01 112136.png>)

<!-- Add verified screenshot: docs/assets/infrastructure/aks-node-pools.png -->

---

## GitHub Actions — DevSecOps Pipeline

CI is designed to **validate code, detect security risks, build an image and produce traceable results** before a deployment configuration is approved.

### Pipeline stages and evidence

| Stage | Tool | Checks performed | Result / report to show |
| --- | --- | --- | --- |
| Source validation | GitHub Actions | Workflow triggers, checkout, job outcomes | Workflow run and status checks |
| Java build and automated tests | Maven | Compilation and configured unit/integration tests | Maven logs; Surefire XML in `target/surefire-reports/` when generated |
| Code quality and SAST | SonarQube Cloud | Bugs, vulnerabilities, maintainability and quality gate | SonarQube Cloud dashboard and quality-gate result |
| Credential leak detection | Gitleaks | Scans configured Git/source scope for exposed secrets | Job output; JSON/SARIF report|
| Container vulnerability analysis | Trivy | Scans configured filesystem/image targets for known vulnerabilities | Severity summary; JSON/SARIF report  |
| Image build and publication | Docker / registry | Build, tag and publish container artifact | Build logs, immutable tag or image digest |

### Pipeline principles

**Security before promotion.** A build is not considered release-ready merely because Docker successfully created an image. Tests and security checks must have appropriate failure handling; GitHub branch rules must require the intended checks for a **mandatory** gate.

**No hardcoded CI credentials.** Registry credentials, SonarQube tokens and other secrets should be injected using protected GitHub Actions secrets or short-lived identities, not placed in workflow YAML.

**Reports and traceability.** Retain the workflow run, test results, scanner output and image revision so a reviewer can trace **source commit → checks → container artifact → GitOps release**. Report files are only described as downloadable artifacts if the workflows actually upload them.

**Review the implementation:** [GitHub Actions runs](https://github.com/bechirjw/crewmeister-app/actions) · [Workflow definitions](.github/workflows/)


c:\Users\bechi\Downloads\New folder\Capture d'écran 2026-11-01 112418.png c:\Users\bechi\Downloads\New folder\Capture d'écran 2026-11-01 112443.png
---

## Helm & Argo CD GitOps

**Helm** packages the Spring Boot Kubernetes resources into parameterized templates. **Argo CD** tracks the GitOps repository state and reconciles the target cluster against the approved configuration.

**Project folders:** [`helm/crewmeister/`](helm/crewmeister/) · [`gitops/`](gitops/)

```bash
# Verify chart syntax and render Kubernetes manifests
helm lint helm/crewmeister -f helm/crewmeister/values-local.yaml
helm template crewmeister helm/crewmeister -f helm/crewmeister/values-local.yaml
```

### Controlled deployment flow

1. CI validates application changes and publishes a versioned image when the configured checks pass.
2. A GitOps change updates the image reference or Helm values.
3. A **pull request is reviewed** and merged under the repository's actual branch-protection rules.
4. Argo CD detects the approved Git revision and synchronizes it according to its configured policy.
5. Kubernetes performs the rollout; the running revision and health status are inspected.

This separates **Continuous Integration** from **review-gated Continuous Delivery**. An approved Git merge can trigger automatic Argo CD reconciliation, without allowing an unchecked code push to deploy directly.

```bash
kubectl get applications.argoproj.io -A
kubectl get pods -A -o wide
```
c:\Users\bechi\Downloads\New folder\Capture d'écran 2026-11-01 114951.png
![alt text](<Capture d'écran 2026-11-01 114742.png>)
**Evidence to include:** a PR with required checks/approval, the changed image version, Argo CD `Synced` / `Healthy` where actually observed, and the successful Kubernetes rollout.

<!-- Add verified screenshot: docs/assets/gitops/argocd-application.png -->

---

## Monitoring, Logging & Alerting

The observability layer is intended to answer three questions: **Is the platform healthy? What went wrong? Who needs to act?**

| Capability | Components / approach | What to demonstrate |
| --- | --- | --- |
| Monitoring | Kubernetes metrics, Prometheus-compatible collection and Grafana dashboards where configured | CPU, memory, node and application workload status |
| Centralized logging | Loki and the configured log collector, queried through Grafana | Searchable, timestamped application or cluster logs |
| Alerting | Grafana Alerting or Alertmanager, depending on the deployed stack | Alert rule, evaluation, firing/resolution and notification test |

The exact metrics collector, Loki ingestion agent and notification channel must be confirmed from deployed manifests. **A configured dashboard does not by itself prove that alert notifications are working.**

```bash
kubectl get pods -A | grep -Ei 'grafana|prometheus|loki|alertmanager'
kubectl get svc -A | grep -Ei 'grafana|prometheus|loki|alertmanager'
kubectl top nodes              # Requires Metrics Server
```

**Evidence to include:** a Grafana dashboard with live data, a Loki log query and a tested alert rule/notification if available.

<!-- Add verified screenshots: docs/assets/monitoring/grafana-dashboard.png ; docs/assets/monitoring/loki-logs.png ; docs/assets/monitoring/alerts.png -->

---

## Persistent Storage — Local Path Provisioner

The on-premises storage workstream uses the **Local Path Provisioner** to dynamically provision node-local PersistentVolumes for Kubernetes PersistentVolumeClaims (PVCs).

```bash
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get storageclass
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pvc -A
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pv
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pods -n local-path-storage
```
![alt text](<Capture d'écran 2026-11-01 115458.png>)
**Benefits:** simple lab storage, declarative PVC management and persistence across supported container/pod restarts when the volume remains available.

**Trade-off:** local-path data is tied to the underlying node. It is **not** automatically replicated across nodes and should not be described as highly available cloud storage. A `Bound` PVC proves binding, while data persistence requires its own read/write verification.

<!-- Add verified screenshot: docs/assets/storage/local-path-pvc.png -->

---

## Application & API Testing

The project includes a Java Spring Boot REST application with Maven tests and an HTTP smoke-test workflow.

```bash
# Run project tests and package the application
./mvnw test
./mvnw package
```

With the application running and a local port-forward active at `127.0.0.1:18080`:

```bash
curl -sS -w '\nHTTP %{http_code}\n' \
  'http://127.0.0.1:18080/user?id=1'
```



**Testing scope:** unit tests, container startup, Kubernetes health, API smoke tests and expected error cases should be recorded separately. A prior test of `GET /user?id=2` returned HTTP 500; that behavior needs retesting or a documented fix before it can be presented as a passing scenario.

<!-- Add verified screenshot: docs/assets/application/api-test.png -->

---

## Repository Structure

```text
crewmeister-app/
├── .github/workflows/          # GitHub Actions pipelines
├── crewmeister-k8s-ansible/    # VMware / Kubernetes Ansible automation
├── terraform/                  # Azure AKS Infrastructure as Code
├── helm/crewmeister/           # Application Helm chart
├── gitops/                     # Argo CD / GitOps definitions
├── scripts/                    # Supporting scripts
├── src/                        # Spring Boot source and tests
├── Dockerfile                  # Container build
├── compose.yaml                # Local Docker Compose environment
├── pom.xml                     # Maven configuration
├── INSTALL.md                  # Installation guide
└── README.md                   # Project overview and evidence map
```

## Evidence Gallery & Documentation

The README is deliberately concise; the supporting proof belongs in screenshots and technical documentation. Recommended image set:

| Screenshot | What it proves |
| --- | --- |
| On-premises nodes + Ansible recap | Automated cluster provisioning and healthy nodes |
| AKS node pools + Terraform | Cloud infrastructure and scheduling separation |
| GitHub Actions + scanner results | CI jobs, tests, quality gate and security feedback |
| GitOps PR + Argo CD | Reviewed desired state and successful reconciliation |
| Grafana + Loki + alerts | Actual operational visibility and alert evaluation |
| Local-path PVC + API response | Persistent storage and a working application |

Store screenshots under `docs/assets/` and link only files that have been captured. Detailed runbooks and troubleshooting notes can be added under `docs/` as they are completed.

## Quick Verification

```bash
# Select the intended cluster before any operation
kubectl config current-context

# Verify infrastructure and workloads
kubectl get nodes -o wide
kubectl get pods -A -o wide --sort-by=.spec.nodeName

# Validate Helm resources (no deployment performed)
helm lint helm/crewmeister -f helm/crewmeister/values-local.yaml
```

**Safety:** do not publish authentication files, `.env` values, Terraform state, personal cloud identifiers or unredacted secrets. Terraform `apply`, Ansible provisioning/reset, and Kubernetes deployment changes should only be executed deliberately against the intended environment.

---

<div align="center">

**Infrastructure as Code · Security in CI · Review-Gated GitOps · Observable Kubernetes**

*Crewmeister DevSecOps engineering project*

</div>
