# Crewmeister — Kubernetes VMware lab (adapted from your Ansible ZIP)

**Status:** YAML/Python-validated starter; not yet executed against your actual VMware VMs.

## Cluster topology (your actual VMs)

| Role | Existing OS hostname | VMware NAT IP |
|---|---|---|
| Control plane | `mastercrewmeister-virtual-machine` | `192.168.88.132` |
| Worker 1 | `k8s-worker1` | `192.168.88.131` |
| Worker 2 | `k8s-worker2` | `192.168.88.133` |

VMs: Ubuntu Desktop 22.04 LTS under VMware Workstation. Controller: Ubuntu WSL2 on Windows. SSH login `master-crewmeister` assumed on each VM. **No hostname is changed by the playbooks.**

### What changed from your uploaded ZIP

- Kept and adapted roles: `common`, `containerd`, `kubernetes`, `control_plane`, `calico`, `workers`, `validate`, `reset`.
- Removed multi-control-plane joins, kube-vip, MetalLB and dsplus addressing. We have one control plane and two workers.
- Updated the repo from unsupported Kubernetes 1.30 to the supported 1.36 package repository, and switched kubeadm configuration to `v1beta4`.
- Retained raw-manifest Calico approach but pinned `v3.32.2` (documented compatible with Kubernetes 1.36); operator recommended for long-lived installations.
- Explicitly configured Calico IP pool `10.244.0.0/16` to avoid overlap with VMware LAN `192.168.88.0/24`.
- Preserved master host OS name by removing the original task that changed hostnames.
- Re-enabled SSH host key verification (original ZIP had it disabled).
- Uses one short-lived kubeadm join command, redacts it from normal Ansible logs.
- No cluster-admin kubeconfig committed to project; optional WSL fetch script stores it in `~/.kube/crewmeister-admin.conf` with mode `0600`.

## Before running

1. Verify VMs still have the three addresses shown above with `hostname -I` on **each** VM. If not, edit `inventory.yml`. Reserve these addresses in VMware DHCP or set stable addresses.
2. Verify all three VMs have **unique** `/etc/machine-id` and SSH host key fingerprints (important because they were cloned).
3. Verify login user `master-crewmeister` exists on all VMs, can sudo, and the WSL2 SSH key has been distributed to each VM.
4. In WSL2 install `ansible`, `openssh-client`, `python3`, `unzip`.
5. Keep project under WSL's Linux filesystem (for example `~/crewmeister-k8s-ansible`), not a shared Windows drive.
6. Each VM should have at least **2 vCPU / 2 GiB RAM**; 4 GiB RAM per node is preferable for application workloads. Host hardware must support all three VMs.
7. Ensure outbound Internet/DNS works from VMs for Ubuntu packages and container images. Do **not** expose port 6443 or SSH to the public Internet.

### From Windows CMD

```cmd
wsl -d Ubuntu-24.04
```

### From Ubuntu WSL2

If the ZIP is in Downloads (adjust username/path as needed):

```bash
sudo apt update && sudo apt install -y ansible unzip openssh-client
cd ~
cp /mnt/c/Users/bechi/Downloads/crewmeister-k8s-ansible-vmware.zip .
unzip crewmeister-k8s-ansible-vmware.zip
cd crewmeister-k8s-ansible

# Verify SSH host fingerprints on each VM via the VMware console before first acceptance.
ssh master-crewmeister@192.168.88.132 hostname
ssh master-crewmeister@192.168.88.131 hostname
ssh master-crewmeister@192.168.88.133 hostname

ansible-inventory --graph
ansible all -m ping
ansible all -b -K -m command -a 'id -u'
ansible-playbook preflight.yml
```

You must see three Ansible `SUCCESS` / `pong` results, then three successful sudo results of `0`, and a passing preflight. If your SSH/sudo username differs from `master-crewmeister`, update the inventory.

## Deploy the cluster (only after preflight passes)

```bash
ansible-playbook site.yml -K
```

This automatically reruns the preflight checks, installs packages on all nodes, initializes the first control plane, installs Calico, joins two workers, and verifies CoreDNS/Calico/readiness. `-K` requests your sudo password. **Do not start a second simultaneous run.**

For local inspection without distributing admin credentials to WSL:

```bash
ssh master-crewmeister@192.168.88.132 \
  'kubectl get nodes -o wide && kubectl get pods -n kube-system'
```

Optional: copy the **high-privilege** admin kubeconfig to your WSL home for later Helm/Terraform experiments (avoid checking it into Git):

```bash
ansible-playbook fetch-kubeconfig.yml -K
export KUBECONFIG=~/.kube/crewmeister-admin.conf
kubectl get nodes -o wide
```

This admin kubeconfig is appropriate only for a controlled local lab. Use a dedicated, scoped identity for long-term CI deployments.

## Acceptance criteria

- [ ] `ansible all -m ping` succeeds on all three machines
- [ ] `ansible-playbook preflight.yml` passes unique-identity, OS and network checks
- [ ] `ansible-playbook site.yml -K` completes without errors
- [ ] `kubectl get nodes` shows 3 nodes Ready; master retains original OS hostname
- [ ] `kubectl get pods -n kube-system` shows healthy Calico and CoreDNS
- [ ] Second `ansible-playbook site.yml -K` does not reinitialize / rejoin nodes
- [ ] `kubectl get storageclass` inspected (MySQL requires storage provisioning)

## Known limits and cautions

- **Not executed against your VMs yet**; success cannot be guaranteed until real runs finish.
- Single control plane is not highly available. All VMs share one Windows machine.
- Persistent storage **not installed** in this cluster phase. Add a suitable provisioner/PVs before MySQL deployment.
- Direct raw-manifest Calico is used to preserve original project; its operator is preferable for upgrade automation.
- kubeadm package versions are selected from the **1.36 minor repository** on first installation, then held. Record actual patch with `kubeadm version` after installation.
- WSL2 -> VMware NAT subnet connectivity depends on Windows/WSL routing and firewalls.
- Worker bootstrap token is recreated on reruns but expires after 2 hours; it is masked in Ansible logs.
- The `reset-cluster.yml` playbook is destructive and deliberately requires `-e confirm_reset=true`.
- Never use original `reset-cluster.yml` if you want to preserve application data.

## Official documentation

- Kubernetes releases: https://kubernetes.io/releases/
- Installing kubeadm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- kubeadm config v1beta4: https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
- Calico (on prem): https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises
