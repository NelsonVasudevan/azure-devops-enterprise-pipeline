# Cost Optimization

This project runs on a personal Azure free-tier account, not a company
subscription with a safety net - every decision below exists because a
mistake here is a real bill, not a Slack message to a cloud team.

## Decisions baked into the Terraform

| Decision | Why |
|---|---|
| `sku_tier = "Free"` on the AKS control plane | The paid "Standard" tier adds an SLA-backed control plane for ~$0.10/hr per cluster - meaningless for a portfolio project, and pure waste at free-tier scale. |
| `node_count = 1`, `Standard_B2s` | Smallest burstable VM size that reliably runs a FastAPI pod + system pods together. Burstable (B-series) bills for baseline CPU with burst credit rather than a flat high rate. |
| No cluster autoscaler enabled | Autoscaling is a feature worth demonstrating in isolation, deliberately, not something to leave running unattended where it could silently scale up under load and burn budget. |
| No ACR provisioned | Docker Hub's free tier covers this project's image storage/pull needs at zero cost; ACR (even Basic tier) is a recurring charge with no benefit here. |
| `azurerm_consumption_budget_resource_group` with 80%/100% alerts | Budget alerts are declared in code, not set up once by hand and forgotten - so re-running `terraform apply` after a `destroy` reliably recreates the safety net too. |

## Manual discipline (not enforceable by Terraform)

- **`terraform destroy` after every working session.** This is the single
  biggest lever - an idle AKS cluster still bills for the VM(s), managed
  disks, and the standard Load Balancer backing the Service. Nothing here
  is worth leaving on overnight by accident.
- **Budget alert email is a floor, not a plan.** By the time an 80% alert
  fires, spend has already happened. It's a backstop for a mistake, not a
  substitute for destroying resources after use.
- **Track a running log of session dates and estimated spend** (see
  `docs/session-log.md` if you keep one) so a surprise charge is traceable
  to a specific session instead of a mystery at bill time.

## Estimated cost per active hour (Central India, approx.)
- 1x `Standard_B2s` node: ~$0.02-0.03/hr
- Standard Load Balancer (from the `LoadBalancer` Service): ~$0.02/hr + data processing
- AKS control plane (Free tier): $0
- Public IP (Standard SKU, attached to LB): small hourly charge while allocated

None of these are exact billing figures - check the Azure Pricing
Calculator for current rates in your region before relying on this for
budget-setting. The point of this table is the *shape* of where cost comes
from, so you know what to `destroy` first if you're short on time and want
to kill the expensive pieces immediately (Load Balancer + Public IP release
faster than waiting on full cluster teardown).

## What would change this at real enterprise scale
Worth being able to say in an interview: at production scale, the next
levers are Reserved Instances / Savings Plans for predictable baseline
load, spot node pools for interruptible batch workloads, and right-sizing
via `kubectl top` + VPA recommendations rather than guessing VM size
up front - none of which make sense to demonstrate on a single-node
free-tier cluster, but the reasoning generalizes.
