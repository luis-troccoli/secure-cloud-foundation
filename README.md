# Secure Cloud Foundation: Federated Identity & Shift-Left Security (Phase 2)

**Read this in:** [English](README.md) | [Español](README.es.md) | [Italiano](README.it.md)

## 🎯 Overview
**Secure Cloud Foundation** is **Phase 2** of a 3-part Azure security portfolio, building directly on [Project Vault](https://github.com/luis-troccoli/project-vault) (Phase 1). Where Phase 1 established the fundamentals — segmented networking, a hardened Key Vault with RBAC — this phase closes two gaps that Phase 1 left as roadmap items: static CI credentials and the absence of automated security scanning.

## 💡 What This Project Adds
* **Federated identity (OIDC):** the CI/CD pipeline authenticates to Azure via GitHub Actions OIDC federation — no long-lived service principal secrets stored anywhere.
* **A real, blocking security gate:** Checkov runs on every push/PR with `soft_fail: false`. If it finds a critical misconfiguration, the pipeline stops before `plan` or `apply` ever run.
* **A real deployment pipeline:** unlike Phase 1 (validate-only), this pipeline runs `terraform plan` and `terraform apply` against a live Azure subscription on merges to `main`.
* **The same hardening as Phase 1**, carried forward: NSG rules in both directions, Key Vault with purge protection and RBAC-based access control via an explicit role assignment.

## 🏗️ Architecture Diagram
![Security Architecture](assets/diagrama_arquitectura.jpg)

## 🛡️ What's Actually Implemented
* **OIDC federation:** `azure/login@v2` authenticates using `id-token: write` permissions — no `AZURE_CLIENT_SECRET` or equivalent stored in GitHub Secrets.
* **Checkov, blocking:** `soft_fail: false` means a critical finding fails the job outright, before any infrastructure changes are even planned.
* **Key Vault, hardened:** `purge_protection_enabled = true`, `enable_rbac_authorization = true`, plus an explicit `Key Vault Secrets Officer` role assignment for the deploying identity.
* **NSG, both directions:** explicit allow rules for HTTPS (443) inbound and outbound, with a deny-all catch-all on each direction.
* **NSG-to-subnet association:** the NSG is actually attached to the subnet — an association that was missing in an earlier draft of this project and would have left the NSG rules defined but never enforced on any traffic.

## 🔍 Component Breakdown
### 1. `main.tf` — Orchestration
![main.tf Analysis](assets/main.png)
* Resource Group, VNet, subnet, and the NSG-to-subnet association.

### 2. `providers.tf` — Trust Boundary
![providers.tf Analysis](assets/provider.png)
* Declares the `azurerm` provider. Authentication itself happens via OIDC in the CI/CD pipeline, not via static credentials in this file.

### 3. `security.tf` — Hardening
![security.tf Analysis](assets/security.png)
* NSG rules (inbound + outbound, default-deny) and the Key Vault, including its RBAC role assignment.

### 4. `variables.tf` — Parameterization
![variables.tf Analysis](assets/variables.png)
* Input variables (region, environment, project name) with sane defaults.

### 5. `outputs.tf` — Traceability
![outputs.tf Analysis](assets/outputs.png)
* Exposes the Resource Group ID, VNet ID, Key Vault URI, and NSG ID post-deployment.

---

## 🛠️ Tech Stack
* **Cloud:** Microsoft Azure (Resource Group, Key Vault with RBAC, Virtual Network, NSG, Entra ID/OIDC)
* **IaC:** HashiCorp Terraform (`azurerm` provider ~> 3.0)
* **Security Scanning:** Checkov (blocking, `soft_fail: false`)
* **CI/CD:** GitHub Actions with OIDC federation
* **Version Control:** Git (GitHub)

## 🤖 CI/CD Pipeline
[![Terraform CI/CD](https://github.com/luis-troccoli/secure-cloud-foundation/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/luis-troccoli/secure-cloud-foundation/actions/workflows/terraform-pipeline.yml/badge.svg)

The pipeline runs, in order: OIDC login → `terraform init` → `terraform fmt -check` → `terraform validate` → Checkov security scan (blocking) → `terraform plan` → `terraform apply` (on `main` only). A failure at any step stops the pipeline before the next one runs.

## 📈 Roadmap (carried into Phase 3)
* **Azure Policy:** continuous compliance monitoring — addressed in [FinTech-Guard-OS](https://github.com/luis-troccoli/fintech-guard-os) (Phase 3).
* **Remote backend:** Azure Storage Account with state locking, for team collaboration.
* **Modular structure:** refactor from flat `.tf` files into `/modules` — addressed in Phase 3.

## 🚀 Deployment Guide
1. Configure OIDC federated credentials in your Azure AD app registration and GitHub repo secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`).
2. Push to a feature branch and open a PR — the pipeline validates and scans automatically.
3. Merge to `main` to trigger `plan` + `apply`.
4. `terraform destroy` when finished, to avoid unwanted costs.

## 🤝 Contribution
Open to PRs and architecture discussion from anyone working on cloud security.
