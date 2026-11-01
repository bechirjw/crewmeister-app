<div align="center">DevSecOps & GitOps Platform
Crewmeister — Secure, Automated Kubernetes Delivery
From source code to a reviewed, observable Kubernetes release







Overview · Architecture · Docker · Ansible · Terraform / AKS · CI/CD · GitOps · Observability · Testing
</div>Overview
Crewmeister is a Java Spring Boot application used to demonstrate an end-to-end DevSecOps and GitOps delivery workflow. The project brings together local containerized development, infrastructure automation, security-aware continuous integration, review-controlled deployments, and Kubernetes observability.
Area	Technologies	Engineering objective
Application and local development	Spring Boot, Maven, Docker, Docker Compose	Repeatable builds and local execution
On-premises Kubernetes	VMware, Ubuntu, Kubernetes, Ansible	Automated multi-node cluster setup
Azure infrastructure	Terraform, Azure Kubernetes Service (AKS)	Reusable Infrastructure as Code
Continuous integration	GitHub Actions, Maven, SonarQube Cloud, Gitleaks, Trivy	Automated tests, code analysis, and security feedback
Continuous delivery	Pull requests, Helm, Argo CD	Traceable, review-controlled GitOps releases
Observability	Grafana, Loki, metrics and alerting components	Workload health, logs, and operational visibility
Persistent storage	PersistentVolumes, PVCs, Local Path Provisioner	Dynamic node-local storage for the on-premises cluster


Implementation note: The screenshots and configuration files are evidence of specific project workstreams. The exact enforcement of security gates, deployment approval rules, Terraform remote backend, and alert notifications must be checked against the active configuration before claiming they are operational.

<<<<<<< HEAD
Architecture
1. DevSecOps and GitOps application delivery
<!-- SCREENSHOT:devsecops-gitops-flow -->The delivery model separates build and security validation from deployment authorization. CI validates the source and can publish a versioned container image; a reviewed change to deployment configuration authorizes the desired version; Argo CD then reconciles Git with Kubernetes according to its synchronization policy.
2. Hybrid infrastructure architecture
<!-- SCREENSHOT:hybrid-infrastructure -->The on-premises VMware cluster demonstrates Kubernetes installation and management with Ansible. Azure AKS demonstrates managed Kubernetes infrastructure defined with Terraform. Helm enables reusable application packaging while keeping environment-specific settings separate.
Docker & Docker Compose
The root Dockerfile packages the Spring Boot service as a container image. [`compose.yaml`](compose.yaml) defines the local multi-container environment and makes startup and troubleshooting repeatable.
# Validate Compose configuration
# Note: configuration rendering may expose resolved environment values.
=======
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

![DevSecOps and GitOps architecture](docs/screenshots/devsecops-gitops-flow.png)

**Important distinction:** CI creates and validates an artifact. A reviewed **GitOps configuration change** authorizes a release. Argo CD then synchronizes approved desired state with the target cluster. The configured branch rules and sync policy determine which steps are enforced automatically.

### 2. Infrastructure architecture

![Hybrid Kubernetes infrastructure architecture](docs/screenshots/hybrid-infrastructure.png)
**Why two environments?** The VMware cluster demonstrates hands-on Kubernetes installation and operations; AKS demonstrates managed Kubernetes infrastructure as code. The same application packaging concepts can be reused while environment-specific settings remain separate.

---

## Docker & Docker Compose

The Spring Boot application is packaged with the root [`Dockerfile`](Dockerfile). [`compose.yaml`](compose.yaml) provides a local, repeatable way to start the services declared by the project without manually launching each container.

```bash
# Validate the Compose configuration without starting services
>>>>>>> 905384e (docs: repair README images and organize screenshots)
docker compose config --quiet

# Build and start services
docker compose up --build -d

# Inspect containers and logs
docker compose ps
docker compose logs --tail=80
<!-- SCREENSHOT:docker-compose -->Containerization and secret-management practices
Practice	Benefit
Externalize passwords, tokens, and connection settings	Avoids embedding credentials in source code or images
Load runtime configuration from protected sources	Separates application code from environment-specific secrets
Exclude sensitive local .env files from Git	Reduces accidental credential disclosure
Tag images with a version or commit SHA	Provides release traceability and easier rollback
Configure health checks and resource settings where applicable	Improves diagnosis and reliability
Separate Compose and Kubernetes configuration	Avoids coupling local development to cluster deployment


Use an .env.example containing placeholder variable names only. Do not commit passwords, private keys, kubeconfigs, or Terraform state. For CI, use protected GitHub secrets or an appropriate short-lived identity mechanism.
On-Premises Kubernetes with Ansible
The on-premises environment uses Ubuntu VMs on VMware. Ansible defines hosts and repeatable cluster configuration through an inventory, playbooks, shared variables, and reusable roles instead of a manual installation procedure.

Code: [`crewmeister-k8s-ansible/`](crewmeister-k8s-ansible/)
Component	Responsibility
inventory.yml	Defines the managed control-plane and worker hosts
ansible.cfg	Centralizes Ansible execution settings
preflight.yml	Checks prerequisites before provisioning
site.yml	Main entry point for cluster automation
roles/	Groups automation tasks into reusable components
group_vars/	Defines shared, non-sensitive inventory settings
fetch-kubeconfig.yml	Retrieves configuration for Kubernetes client access
reset-cluster.yml	Defines reset operations; run only when intentionally rebuilding

<<<<<<< HEAD
=======
---
![Docker Compose environment](docs/screenshots/docker-compose.png)
## On-Premises Kubernetes with Ansible
>>>>>>> 905384e (docs: repair README images and organize screenshots)

Automation workflow and benefits
The playbooks cover cluster setup responsibilities such as host preparation, Kubernetes prerequisites, container runtime configuration, control-plane initialization, worker joining, and networking/add-ons. Actual role names and execution order can be inspected in site.yml and roles/.

Why Ansible? Repeatable provisioning, modularity, parameterized hosts, clearer diagnostics, and a basis for checking idempotence.
cd crewmeister-k8s-ansible
ansible-inventory -i inventory.yml --graph
ansible-playbook -i inventory.yml site.yml --syntax-check
ansible-playbook -i inventory.yml site.yml --list-tasks
<<<<<<< HEAD
<!-- SCREENSHOT:ansible-automation -->On-premises cluster validation:
=======
```
<!-- Missing screenshot: ansible-inventory.png -->
**Cluster verification** (using the on-premises kubeconfig already prepared in the WSL environment):

```bash
>>>>>>> 905384e (docs: repair README images and organize screenshots)
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get nodes -o wide
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pods -A -o wide --sort-by=.spec.nodeName
<!-- SCREENSHOT:onprem-cluster-nodes -->Azure AKS with Terraform
Terraform defines Azure infrastructure as code, including the architecture for Azure Kubernetes Service (AKS). The project distinguishes a system node pool for cluster services from a user node pool intended for application workloads; confirm the current deployed pool count in Azure before presenting it as a live result.

<<<<<<< HEAD
Code: [`terraform/`](terraform/)
Infrastructure design
- Reusable modules and variables support configuration consistency and environment-specific inputs.
- System and user node pools provide a design for separating platform and application workloads.
- Terraform plans make proposed changes reviewable before deployment.
- State protection keeps infrastructure state and sensitive backend credentials out of Git.
Terraform backend and state
An Azure Storage (azurerm) backend is an appropriate remote-state option because it supports shared state and locking. Whether this backend is actually configured must be verified in terraform/ before describing it as implemented. Remote state is not automatically established by running terraform init against a local backend.
=======
```
![On-premises Kubernetes cluster nodes](docs/screenshots/onprem-cluster-nodes.png)


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
>>>>>>> 905384e (docs: repair README images and organize screenshots)
cd terraform
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
terraform plan previews infrastructure changes; it does not prove that the resources were deployed. Use the AKS node-pool information and actual terraform apply output, where available, as deployment evidence.
kubectl --kubeconfig="$HOME/.kube/crewmeister-aks" get nodes -L agentpool
kubectl --kubeconfig="$HOME/.kube/crewmeister-aks" get pods -A -o wide
<<<<<<< HEAD
<!-- SCREENSHOT:aks-node-pools --><!-- SCREENSHOT:terraform-apply -->GitHub Actions — DevSecOps Pipeline
GitHub Actions coordinates the CI steps required to build, test, inspect, and publish the application artifact. The configured jobs and enforcement rules determine which validations are mandatory.
CI stages and reports
Stage	Tool	Purpose	Evidence / output
Build and tests	Maven	Compile and execute configured tests	CI logs; Surefire XML under target/surefire-reports/, if generated
Code analysis	SonarQube Cloud	Inspect quality, maintainability, and security findings	Dashboard, issue summary, quality-gate result
Secret detection	Gitleaks	Detect exposed credentials in the configured scan scope	Scan logs; report artifact if uploaded
Vulnerability scanning	Trivy	Identify known vulnerabilities in configured filesystem/image targets	Scan result by severity; SARIF/JSON if generated
Container build	Docker	Build and tag the application image	Build logs and image identifier
Image publication	Container registry	Publish a traceable artifact	Registry entry, tag or image digest


Pipeline security practices
- Security validation before promotion: a successful image build is not enough to authorize a release.
- Meaningful gates: required checks and appropriate non-zero exit behavior must be configured to block unsafe changes.
- No credentials in YAML: sensitive values should come from GitHub Actions secrets or a short-lived identity mechanism.
- Traceability: source commit, test and scan results, image version, and GitOps revision should be correlatable.
- Report retention: test and scanner reports count as downloadable artifacts only if workflow jobs actually upload them.
Implementation: [GitHub Actions workflows](.github/workflows/) · Workflow runs
<!-- SCREENSHOT:ci-pipeline-1 --><!-- SCREENSHOT:ci-pipeline-2 -->Helm & Argo CD GitOps
Helm packages Kubernetes manifests into configurable templates. Argo CD compares the approved GitOps desired state with the cluster and synchronizes it according to the application's configured policy.

Code: [`helm/crewmeister/`](helm/crewmeister/) · [`gitops/`](gitops/)
# From repository root
=======
```
![Azure AKS node pools](docs/screenshots/aks-node-pools.png)

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


---

![GitHub Actions pipeline execution](docs/screenshots/ci-pipeline-1.png)

![GitHub Actions checks and reports](docs/screenshots/ci-pipeline-2.png)

## Helm & Argo CD GitOps

**Helm** packages the Spring Boot Kubernetes resources into parameterized templates. **Argo CD** tracks the GitOps repository state and reconciles the target cluster against the approved configuration.

**Project folders:** [`helm/crewmeister/`](helm/crewmeister/) · [`gitops/`](gitops/)

```bash
# Verify chart syntax and render Kubernetes manifests
>>>>>>> 905384e (docs: repair README images and organize screenshots)
helm lint helm/crewmeister -f helm/crewmeister/values-local.yaml
helm template crewmeister helm/crewmeister -f helm/crewmeister/values-local.yaml
Review-controlled delivery flow
1. Application CI runs tests and security analysis, then publishes the versioned image if its configured checks pass.
2. The image reference or Helm values are updated in GitOps configuration.
3. A pull request receives the required reviews/checks, if enforced by repository rules, before it is merged.
4. Argo CD observes the approved Git revision and reconciles Kubernetes.
5. The team verifies the deployed image, rollout state, application health, and synchronization status.
This is review-gated Continuous Delivery: the authorized Git change can be automatically synchronized without an unrestricted direct deployment from a CI job.
kubectl get applications.argoproj.io -A
kubectl get pods -A -o wide
<<<<<<< HEAD
<!-- SCREENSHOT:gitops-release --><!-- SCREENSHOT:argocd-application -->Monitoring, Logging & Alerting
The observability workstream targets three operational questions: Is the system healthy? What failed? Who should be notified?
Capability	Components	Evidence to capture
Monitoring	Metrics collection and Grafana dashboards	CPU/memory trends, node and workload status
Logging	Loki, configured log collector, Grafana Explore	Searchable application and Kubernetes logs
Alerting	Grafana Alerting or Alertmanager, where deployed	Rule conditions, evaluation state and notification test
=======
```
![Argo CD application deployment](docs/screenshots/argocd-application.png)
**Evidence to include:** a PR with required checks/approval, the changed image version, Argo CD `Synced` / `Healthy` where actually observed, and the successful Kubernetes rollout.
>>>>>>> 905384e (docs: repair README images and organize screenshots)


<<<<<<< HEAD
Validate which metrics collector, log collection agent, and alert receiver are actually deployed before identifying them as working integrations. A Grafana dashboard by itself does not prove that notifications are being delivered.
=======
---

![GitOps release evidence](docs/screenshots/gitops-evidence.png)

## Monitoring, Logging & Alerting

The observability layer is intended to answer three questions: **Is the platform healthy? What went wrong? Who needs to act?**

| Capability | Components / approach | What to demonstrate |
| --- | --- | --- |
| Monitoring | Kubernetes metrics, Prometheus-compatible collection and Grafana dashboards where configured | CPU, memory, node and application workload status |
| Centralized logging | Loki and the configured log collector, queried through Grafana | Searchable, timestamped application or cluster logs |
| Alerting | Grafana Alerting or Alertmanager, depending on the deployed stack | Alert rule, evaluation, firing/resolution and notification test |

The exact metrics collector, Loki ingestion agent and notification channel must be confirmed from deployed manifests. **A configured dashboard does not by itself prove that alert notifications are working.**

```bash
>>>>>>> 905384e (docs: repair README images and organize screenshots)
kubectl get pods -A | grep -Ei 'grafana|prometheus|loki|alertmanager'
kubectl get svc -A | grep -Ei 'grafana|prometheus|loki|alertmanager'
kubectl top nodes  # Requires Metrics Server
<!-- SCREENSHOT:grafana-dashboard --><!-- SCREENSHOT:loki-logs --><!-- SCREENSHOT:alerts -->Persistent Storage — Local Path Provisioner
The on-premises cluster uses Local Path Provisioner for dynamic provisioning of node-local Kubernetes PersistentVolumes from PersistentVolumeClaims (PVCs).
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get storageclass
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pvc -A
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pv
KUBECONFIG="$HOME/.kube/crewmeister-admin.conf" kubectl get pods -n local-path-storage
<<<<<<< HEAD
<!-- SCREENSHOT:local-path-storage -->Benefits: straightforward storage for a local lab, declarative PVC lifecycle, and persistence through supported pod restarts while the underlying data remains available.
=======
```
![Kubernetes local path persistent storage](docs/screenshots/local-path-storage.png)
**Benefits:** simple lab storage, declarative PVC management and persistence across supported container/pod restarts when the volume remains available.
>>>>>>> 905384e (docs: repair README images and organize screenshots)

Trade-off: local-path volumes are tied to a particular node. They do not provide automatic replication or high availability. A Bound PVC verifies successful binding; persistence of actual data requires a separate write/read test.
Application & API Testing
The Spring Boot application supports Maven-based verification and an HTTP smoke test of its REST API.
./mvnw test
./mvnw package
With the application running and local port-forwarding configured on port 18080:
curl -sS -w '\nHTTP %{http_code}\n' \
  'http://127.0.0.1:18080/user?id=1'
A successful response should be validated alongside Kubernetes readiness and container startup. Test expected error responses separately; a previous GET /user?id=2 run returned HTTP 500 and needs retesting or a documented resolution.
<!-- SCREENSHOT:api-test -->Repository Structure
crewmeister-app/
├── .github/workflows/          # GitHub Actions pipelines
├── crewmeister-k8s-ansible/    # VMware Kubernetes automation
├── terraform/                  # Azure AKS Infrastructure as Code
├── helm/crewmeister/           # Application Helm chart
├── gitops/                     # Argo CD / GitOps manifests
├── docs/screenshots/           # Screenshots referenced by this README
├── src/                       # Spring Boot source and tests
├── Dockerfile                 # Container build
├── compose.yaml               # Local development environment
├── pom.xml                    # Maven project definition
├── INSTALL.md                 # Installation instructions
└── README.md                  # Project overview and evidence
Evidence and Documentation
Evidence	What it demonstrates
On-premises nodes + Ansible automation	Automated cluster setup and node readiness
AKS node pools + Terraform	Azure infrastructure and scheduling topology
GitHub Actions + scanner results	CI execution, tests, analysis, and security findings
GitOps PR + Argo CD	Deployment review, reconciliation, and application health
Grafana + Loki + alerts (when captured)	Operational metrics, logs, and alert behavior
PVC + REST API response	Storage provisioning and application availability


Screenshot evidence is stored under docs/screenshots/ and appears above only after the corresponding image has been imported. Add supporting runbooks and incident notes under docs/ as they are written.
Screenshot convention
Images are referenced relative to the repository root, for example:
![AKS node pools](docs/screenshots/aks-node-pools.png)
Every published image link must point to a real file with exactly the same name and capitalization. Screenshots should be reviewed for exposed secrets before committing.
Quick Verification
# Confirm that the intended context is active
kubectl config current-context

# Inspect cluster infrastructure and running workloads
kubectl get nodes -o wide
kubectl get pods -A -o wide --sort-by=.spec.nodeName

# Validate chart rendering without deployment
helm lint helm/crewmeister -f helm/crewmeister/values-local.yaml
Security: Do not commit authentication files, secrets, Terraform state, raw environment files, or unredacted screenshots. Operations such as terraform apply, Ansible provisioning/reset, and Kubernetes mutations must be run deliberately against the intended environment.

<div align="center">Infrastructure as Code · Security in CI · Review-Gated GitOps · Observable Kubernetes

Crewmeister DevSecOps engineering project
</div>
