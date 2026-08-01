# AKS Upgrade Strategy

## Why this matters
AKS control-plane and node-pool Kubernetes versions fall out of support on a
rolling ~1-year cycle. An unmanaged cluster silently drifts toward an
unsupported version, at which point Azure can force-upgrade it during a
maintenance window you don't control. This doc defines how upgrades are
planned and executed for this cluster instead.

## Versioning approach
- `kubernetes_version` in `terraform/variables.tf` is left `null` by default,
  which lets AKS pick the current default stable version on first create.
- For every subsequent upgrade, the version is pinned explicitly in
  `terraform.tfvars` and bumped deliberately - never left to drift silently.
- Check available versions before bumping:
  ```bash
  az aks get-upgrades --resource-group rg-azure-devops-pipeline --name adep-aks -o table
  ```

## Upgrade order
1. **Control plane first, node pool second.** AKS supports this split;
   upgrading the control plane alone doesn't touch running workloads.
   ```bash
   az aks upgrade --resource-group rg-azure-devops-pipeline --name adep-aks \
     --kubernetes-version <new-version> --control-plane-only
   ```
2. **Node pool upgrade** via Terraform (`kubernetes_version` applied to the
   node pool too) or directly:
   ```bash
   az aks nodepool upgrade --resource-group rg-azure-devops-pipeline \
     --cluster-name adep-aks --name system --kubernetes-version <new-version>
   ```

## Surge strategy
The default node pool sets `max_surge = "10%"` in `upgrade_settings`. On a
single-node free-tier cluster this rounds up to one extra node spun up
temporarily during upgrade, so the existing pod gets safely drained and
rescheduled before the old node is removed - avoiding downtime even at
`node_count = 1`. This is intentionally the same "surge, don't replace
in-place" pattern used in the Repo 3 Helm/ArgoCD rollout strategy.

## Safety checks before any upgrade
- `kubectl get nodes` and `kubectl get pods -A` clean (no CrashLoopBackOff,
  no pending evictions) before starting.
- `terraform plan` reviewed and shows only the expected version-bump diff -
  no unrelated resource replacement.
- Budget check: an extra surge node briefly doubles node cost during the
  upgrade window. On `Standard_B2s` at free-tier scale this is cents, but
  it's called out here because it's exactly the kind of thing that erodes a
  hard monthly budget cap if forgotten.

## Rollback
AKS does not support "downgrading" a cluster. If an upgrade introduces a
regression, the mitigation is:
1. Roll the *application* back via the pipeline's `kubectl rollout undo`
   (independent of cluster version).
2. If the cluster itself is unhealthy, redeploy from Terraform state on a
   known-good version rather than attempting an in-place downgrade -
   consistent with the GitOps recovery pattern proven in Repo 3 after the
   etcd corruption incident.

## Cadence
For a portfolio/demo cluster there's no production SLA driving cadence, but
the documented policy is: check `az aks get-upgrades` monthly, upgrade
within one minor version of the latest supported release, and never let the
cluster reach an AKS-deprecated version (Azure sends automatic warnings via
email/portal ahead of forced upgrades).
