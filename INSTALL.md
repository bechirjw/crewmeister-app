# Crewmeister — Kubernetes / Helm / GitHub Actions / Argo CD

This archive contains only additive files. Extract at the root of `~/crewmeister-app`. It does not replace Terraform, Dockerfile, pom.xml or existing Ansible files.

## Important assumptions

- Upstream app Spring Boot 3.3.5 / Java 17, MySQL challenge, Flyway; use `SPRING_DATASOURCE_*` and `SPRING_DATASOURCE_WRITER_URL`.
- Image already pushed: `ghcr.io/bechirjw/crewmeister-app:1.0`, digest pinned in `values-local.yaml`.
- MySQL uses `mysql:8.4`, `MYSQL_DATABASE=challenge`, user `crewmeister`.
- Namespace `crewmeister` exists and belongs to Terraform. StorageClass `local-path` exists.
- Existing secret `crewmeister-db` must be created separately in the target namespace before any deployment. Keys: `app-password`, `root-password`.
- Ensure the GHCR package can be pulled anonymously from the Kubernetes workers, or create an imagePullSecret and reference it via Helm values.
- Keep `velero` deferred. Monitor PV backup/restore separately.

## 1. Local preparation

```bash
cd ~/crewmeister-app
helm lint helm/crewmeister -f helm/crewmeister/values-local.yaml
helm template crewmeister helm/crewmeister -f helm/crewmeister/values-local.yaml > /tmp/crewmeister-rendered.yaml
kubectl --kubeconfig="$HOME/.kube/crewmeister-admin.conf" get nodes -o wide
kubectl --kubeconfig="$HOME/.kube/crewmeister-admin.conf" get storageclass local-path
```

## 2. Create database Secret (never commit it)

```bash
K="kubectl --kubeconfig=$HOME/.kube/crewmeister-admin.conf"
$K get namespace crewmeister
umask 077
read -rsp 'MySQL application password: ' APP_PASSWORD; echo
read -rsp 'MySQL root password: ' ROOT_PASSWORD; echo
secret_file=$(mktemp)
printf 'app-password=%s\nroot-password=%s\n' "$APP_PASSWORD" "$ROOT_PASSWORD" > "$secret_file"
$K -n crewmeister create secret generic crewmeister-db --from-env-file="$secret_file"
rm -f "$secret_file"; unset APP_PASSWORD ROOT_PASSWORD
```

The Secret has its own lifecycle. Argo CD must not manage or prune it. Kubernetes Secrets are not encrypted just because they are base64 encoded. For AKS use Key Vault + workload identity/external secrets later.

## 3. Smoke test with Helm (optional)

Do **not** install the chart directly using Helm if Argo CD will own the same release. To preview, use `helm template`. For a real cluster deployment, use Argo CD after committing these files to Git.

## 4. GitOps bootstrap

Verify `git remote get-url origin`, GitHub default branch and repository visibility. Replace `REPLACE_OWNER` and `REPLACE_REPOSITORY` in both `gitops/**/*.yaml` before pushing. For a private repository, configure Argo CD read access first.

```bash
kubectl --kubeconfig="$HOME/.kube/crewmeister-admin.conf" apply -f gitops/bootstrap/local-root.yaml
kubectl --kubeconfig="$HOME/.kube/crewmeister-admin.conf" -n argocd get applications
kubectl --kubeconfig="$HOME/.kube/crewmeister-admin.conf" -n crewmeister get pods,pvc -o wide
```

`local-root` is an App-of-Apps bootstrap for `gitops/apps/local`. The child Application deploys Helm to namespace `crewmeister` already owned by Terraform. Never register the same chart directly with Terraform.

## 5. CI/CD

`.github/workflows/ci-cd.yml` tests Maven against disposable MySQL, lints/renders Helm, builds and pushes an image to GHCR when `main` changes, and proposes a PR updating `values-local.yaml` to the new immutable image digest. After PR approval/merge, Argo CD synchronizes the new image.

GitHub repository Settings > Actions > General > Workflow permissions: allow read/write permissions as appropriate and 'Allow GitHub Actions to create and approve pull requests' if available. Protect `main`, use code review for promotion. Workflow `contents: write` and `pull-requests: write` permissions are job-scoped. Make the GHCR package public for unauthenticated cluster pulls, or provision a pull secret.

## 6. Verify app and persistence

```bash
K="kubectl --kubeconfig=$HOME/.kube/crewmeister-admin.conf"
$K -n crewmeister get pods,pvc -o wide
$K -n crewmeister rollout status statefulset/crewmeister-mysql --timeout=300s
$K -n crewmeister rollout status deployment/crewmeister-app --timeout=300s
$K -n crewmeister port-forward svc/crewmeister-app 8080:8080
# in another terminal: curl -f http://localhost:8080/actuator/health
```

Test Flyway data, create a user with the application's actual API schema, delete/recreate the MySQL Pod (NOT its PVC), and verify data survives. Do not delete the PVC with `Retain` until backup/restore behavior has been documented. Remember: Local Path storage is node-bound, not a backup. MySQL requires transaction-consistent backups when Velero is added.

## 7. Prometheus endpoint

The supplied `ServiceMonitor` is OFF by default: upstream pom has Actuator, but not `micrometer-registry-prometheus`. Add the dependency to pom.xml and build a new image; then set `serviceMonitor.enabled: true` in values-local.yaml and verify `http://localhost:8080/actuator/prometheus`.

## 8. AKS

`values-aks.yaml` is a STARTER only. Verify the AKS StorageClass, node pool capacity, GHCR access and Secret integration. The Azure `monitoring` Terraform module and state are separate from application GitOps; adapt a separate Argo CD Application for AKS. Do not apply local app-affinity restrictions or local-path to AKS.
