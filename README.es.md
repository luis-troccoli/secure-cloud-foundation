# Secure Cloud Foundation: Identidad Federada y Seguridad Shift-Left (Fase 2)

**Leer en:** [English](README.md) | [Español](README.es.md) | [Italiano](README.it.md)

## 🎯 Visión General
**Secure Cloud Foundation** es la **Fase 2** de un portfolio de seguridad Azure en 3 partes, construido directamente sobre [Project Vault](https://github.com/luis-troccoli/project-vault) (Fase 1). Donde la Fase 1 estableció los fundamentos — red segmentada, un Key Vault hardened con RBAC — esta fase cierra dos huecos que la Fase 1 dejó como pendientes: credenciales estáticas en CI y la ausencia de escaneo de seguridad automatizado.

## 💡 Qué Agrega Este Proyecto
* **Identidad federada (OIDC):** el pipeline de CI/CD se autentica contra Azure vía federación OIDC de GitHub Actions — sin secretos de service principal de larga duración almacenados en ningún lado.
* **Un security gate real y bloqueante:** Checkov corre en cada push/PR con `soft_fail: false`. Si encuentra una mala configuración crítica, el pipeline se detiene antes de que `plan` o `apply` lleguen a ejecutarse.
* **Un pipeline de despliegue real:** a diferencia de la Fase 1 (solo validación), este pipeline ejecuta `terraform plan` y `terraform apply` contra una suscripción de Azure real en merges a `main`.
* **El mismo hardening de la Fase 1**, llevado adelante: reglas NSG en ambas direcciones, Key Vault con purge protection y control de acceso basado en RBAC vía una asignación de rol explícita.

## 🏗️ Diagrama de Arquitectura
![Arquitectura de Seguridad](assets/diagrama_arquitectura.png)

## 🛡️ Lo que Realmente Está Implementado
* **Federación OIDC:** `azure/login@v2` se autentica usando permisos `id-token: write` — sin ningún `AZURE_CLIENT_SECRET` ni equivalente almacenado en GitHub Secrets.
* **Checkov, bloqueante:** `soft_fail: false` significa que un hallazgo crítico falla el job directamente, antes de que se planifique cualquier cambio de infraestructura.
* **Key Vault, hardened:** `purge_protection_enabled = true`, `enable_rbac_authorization = true`, más una asignación explícita del rol `Key Vault Secrets Officer` para la identidad que despliega.
* **NSG, ambas direcciones:** reglas allow explícitas para HTTPS (443) en entrada y salida, con una regla deny-all de cierre en cada dirección.
* **Asociación NSG-subnet:** el NSG está realmente conectado a la subnet — una asociación que faltaba en un borrador anterior de este proyecto y que habría dejado las reglas del NSG definidas pero nunca aplicadas a ningún tráfico.

## 🔍 Análisis de Componentes
### 1. `main.tf` — Orquestación
![Análisis del main.tf](assets/main.png)
* Resource Group, VNet, subnet, y la asociación NSG-subnet.

### 2. `providers.tf` — Límite de Confianza
![Análisis del providers.tf](assets/providers.png)
* Declara el provider `azurerm`. La autenticación en sí ocurre vía OIDC en el pipeline de CI/CD, no vía credenciales estáticas en este archivo.

### 3. `security.tf` — Hardening
![Análisis del security.tf](assets/security.png)
* Reglas NSG (entrada + salida, deny-all por defecto) y el Key Vault, incluyendo su asignación RBAC.

### 4. `variables.tf` — Parametrización
![Análisis del variables.tf](assets/variables.png)
* Variables de entrada (región, entorno, nombre del proyecto) con valores por defecto razonables.

### 5. `outputs.tf` — Trazabilidad
![Análisis del outputs.tf](assets/outputs.png)
* Expone el ID del Resource Group, el ID de la VNet, el URI del Key Vault y el ID del NSG tras el despliegue.

---

## 🛠️ Tech Stack
* **Cloud:** Microsoft Azure (Resource Group, Key Vault con RBAC, Virtual Network, NSG, Entra ID/OIDC)
* **IaC:** HashiCorp Terraform (provider `azurerm` ~> 3.0)
* **Escaneo de Seguridad:** Checkov (bloqueante, `soft_fail: false`)
* **CI/CD:** GitHub Actions con federación OIDC
* **Control de Versiones:** Git (GitHub)

## 🤖 Pipeline de CI/CD
[![Terraform CI/CD](https://github.com/luis-troccoli/secure-cloud-foundation/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/luis-troccoli/secure-cloud-foundation/actions/workflows/terraform-pipeline.yml/badge.svg)

El pipeline ejecuta, en orden: login OIDC → `terraform init` → `terraform fmt -check` → `terraform validate` → escaneo de seguridad con Checkov (bloqueante) → `terraform plan` → `terraform apply` (solo en `main`). Un fallo en cualquier paso detiene el pipeline antes de que corra el siguiente.

## 📈 Roadmap (continúa en la Fase 3)
* **Azure Policy:** monitoreo continuo de compliance — resuelto en [FinTech-Guard-OS](https://github.com/luis-troccoli/fintech-guard-os) (Fase 3).
* **Backend remoto:** Azure Storage Account con bloqueo de estado, para trabajo colaborativo.
* **Estructura modular:** refactorización de archivos `.tf` planos a `/modules` — resuelto en la Fase 3.

## 🚀 Guía de Despliegue
1. Configurá las credenciales federadas OIDC en tu Azure AD app registration y en los secrets del repo de GitHub (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`).
2. Hacé push a una feature branch y abrí un PR — el pipeline valida y escanea automáticamente.
3. Mergeá a `main` para disparar `plan` + `apply`.
4. `terraform destroy` cuando termines, para evitar costos indeseados.

## 🤝 Contribución
Abierto a PRs y discusión de arquitectura de cualquiera trabajando en cloud security.
