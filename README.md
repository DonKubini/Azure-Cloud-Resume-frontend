# Azure Cloud Resume Challenge — Frontend

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

The front-end for my submission to the [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) on Microsoft Azure. It's a single, self-contained HTML resume, styled for both on-screen viewing and clean A4/PDF export, with a live visitor counter powered by a serverless backend.

> 🔗 **Related repository:** [Azure-Cloud-Resume-backend](https://github.com/DonKubini/Azure-Cloud-Resume-backend) — the Azure Function + storage API that serves the visitor count.

## Overview

This site is deployed as a static website and calls out to an Azure Function on load to fetch and increment a visitor counter, which is then rendered directly on the page.

```
Browser → Static site (Azure Storage) → GET /api/GetResumeCounter → Azure Function → Table Storage
```

## Tech Stack

| Layer | Technology |
|---|---|
| Markup / Styling | HTML5, embedded CSS (print-optimized, A4 layout) |
| Interactivity | Vanilla JavaScript (`fetch` API) |
| Hosting | Azure Storage static website (`azurerm_storage_account_static_website`) |
| Infrastructure as Code | Terraform (`infrastructure/`) |
| CI/CD auth | GitHub OIDC federation → Azure Managed Identity |

## Repository Structure

```
.
├── index.html          # Single-page resume (markup, styles, and visitor-counter script)
├── infrastructure/     # Terraform: resource group, storage account, static website, OIDC identity
├── .gitignore
├── LICENSE              # MIT
└── README.md
```

## How It Works

`index.html` is a fully self-contained document — the styling is embedded in a `<style>` block and tuned for A4 print output, so the page doubles as a clean, printable/PDF-exportable resume as well as a web page.

On `DOMContentLoaded`, a small script calls the backend API and writes the result into the page:

```js
const apiUrl = "https://<your-function-app>.azurewebsites.net/api/GetResumeCounter";
fetch(apiUrl)
  .then(res => res.text())
  .then(count => { document.getElementById("visitor-count").innerText = count; })
  .catch(() => { document.getElementById("visitor-count").innerText = "Unavailable"; });
```

If the API call fails for any reason, the counter gracefully falls back to displaying `Unavailable` rather than breaking the page.

## Local Development

No build step or dependencies are required — it's plain HTML/CSS/JS.

```bash
git clone https://github.com/DonKubini/Azure-Cloud-Resume-frontend.git
cd Azure-Cloud-Resume-frontend

# Serve locally, e.g.:
python -m http.server 8080
# then open http://localhost:8080
```

Before testing locally, point the `apiUrl` constant in `index.html` at your own deployed instance of the [backend Function](https://github.com/DonKubini/Azure-Cloud-Resume-backend) (or run it locally with `func start` and use `http://localhost:7071/api/GetResumeCounter`).

## Infrastructure

Hosting is provisioned with **Terraform** (`infrastructure/`). It defines:

| Resource | Purpose |
|---|---|
| `azurerm_resource_group` | Resource group for all (frontend AND backend) resources |
| `azurerm_storage_account` (StorageV2, LRS) | Backs the static website |
| `azurerm_storage_account_static_website` | Enables static website hosting, `index.html` as index document |
| `azurerm_user_assigned_identity` | Dedicated managed identity for GitHub Actions deployments |
| `azurerm_role_assignment` | Grants the identity **Storage Blob Data Contributor** on the storage account |
| `azurerm_federated_identity_credential` | OIDC trust between the identity and this GitHub repo's `main` branch — no client secrets stored in GitHub |

Uploading `index.html` to the `$web` container is intentionally **not** done by Terraform — it's handled by a GitHub Actions workflow authenticating via the OIDC federated identity above (the equivalent `azurerm_storage_blob` resource is included in the code, commented out, as an alternative if you'd rather upload via Terraform directly).

Required Terraform variables:

| Variable | Description |
|---|---|
| `resource_group_name` | Name of the resource group to create |
| `location` | Azure region |
| `storage_account_name` | Globally-unique storage account name |
| `github_repository` | `owner/repo` used to scope the OIDC federation's `subject` claim |

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Deployment

1. Apply the Terraform in `infrastructure/` to provision the resource group, storage account, and OIDC-federated managed identity (see above).
2. In GitHub, configure the repo's Actions to authenticate via the federated identity (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as repo/environment variables/secrets).
3. On push to `main`, have a GitHub Actions workflow log in via OIDC and sync `index.html` to the storage account's `$web` container.
4. (Optional) Front the storage endpoint with Azure CDN / Front Door for HTTPS on a custom domain and edge caching.
5. Point `apiUrl` in `index.html` at your deployed backend Function's `GetResumeCounter` endpoint.

## Roadmap

- [ ] Add basic end-to-end tests for the visitor counter

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

## Author

**Jakub Šišma**
[GitHub](https://github.com/DonKubini) · [LinkedIn](https://linkedin.com/in/jakub-šišma-7b31871b5/)
