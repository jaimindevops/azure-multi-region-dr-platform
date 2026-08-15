---

An enterprise-grade, budget-governed Multi-Region Active/Passive Disaster Recovery (DR) and LLMOps deployment on Microsoft Azure. Built with modular **Bicep Infrastructure as Code (IaC)**, **Azure Kubernetes Service (AKS)**, **Geo-Replicated Azure Container Registry (ACR Premium)**, **Azure Traffic Manager**, and a real-time **Multi-Channel Alerting Engine (Email + Slack)**.

---

## 🏛️ High-Level System Architecture



```

```
                              [ Global User Traffic ]
                                         │
                                         ▼
                    ┌─────────────────────────────────────────┐
                    │    Azure Traffic Manager (DNS Global)   │
                    │    (Routing Method: Priority Active/DR) │
                    └────────────────────┬────────────────────┘
                                         │
                  ┌──────────────────────┴──────────────────────┐
                  │ Priority 1 (Active)                         │ Priority 2 (Passive DR)
                  ▼                                             ▼
    ┌───────────────────────────┐                 ┌───────────────────────────┐
    │   Primary Region: East US │                 │  Secondary Region: West US│
    │   rg-dr-primary-eastus    │                 │  rg-dr-secondary-westus   │
    ├───────────────────────────┤                 ├───────────────────────────┤
    │ ☸️ AKS: aks-primary-eastus │                 │ ☸️ AKS: aks-secondary-west│
    │ 🌐 Custom VNet / Subnet   │                 │ 🌐 Custom VNet / Subnet   │
    │ 🗄️ ACR Geo-Replication    │◄───(Sync)──────►│ 🗄️ ACR Geo-Replication    │
    │ 🔔 Action Group & Alerts  │                 │                           │
    └─────────────┬─────────────┘                 └───────────────────────────┘
                  │ (Activity Log Event Trigger)
                  ▼
    ┌───────────────────────────────────────────────────────────┐
    │                Azure Monitor Action Group                 │
    │                     (ag-dr-alerts)                        │
    └─────────────┬───────────────────────────────┬─────────────┘
                  │                               │
                  ▼                               ▼
    ┌───────────────────────────┐   ┌───────────────────────────┐
    │  ✉️ Direct Admin Email     │   │  💬 Slack Live Channel    │
    │  (jaimincanada18@...)     │   │  (#all-cloud-defense)     │
    └───────────────────────────┘   └───────────────────────────┘

```
---

## 🚀 Key Engineering Pillars

### 1. 🌍 Active/Passive Multi-Region Disaster Recovery
- **Primary Region (`eastus`):** Hosts the primary workload and production ingress.
- **Secondary DR Region (`westus`):** Warm/standby compute cluster provisioned to absorb failover traffic instantly during regional outage simulations.
- **DNS Failover Automation:** Azure Traffic Manager actively probes regional AKS health endpoints every 30 seconds. If `aks-primary-eastus` fails or is deallocated, DNS routing shifts seamlessly from Priority 1 to Priority 2 (`aks-secondary-westus`).

### 2. 🗄️ Geo-Replicated Container Registry
- Provisions a unified Azure Container Registry (ACR Premium) with asynchronous geo-replication across `East US` and `West US`.
- Container images pulled in `West US` experience local network latency with zero cross-region egress overhead during failover events.

### 3. 🔔 Multi-Channel Observability & Incident Response
- **Activity Log Alert Rules (`alert-aks-primary-health`):** Monitors Azure Resource Manager administrative lifecycle events (`Microsoft.ContainerService/managedClusters/write`, start/stop actions).
- **Dual-Channel Notification Plane:** Automatically dispatches structured alert schemas to:
  1. **Tier-1 Admin Email:** Direct escalation inbox (`jaimincanada18@gmail.com`).
  2. **Slack ChatOps:** Dedicated incident response channel (`#all-cloud-defense`).

### 4. 💰 FinOps & Strict Budget Governance ($200 Credit Cap)
- **Zero-Idle Compute Policy:** Implements Azure CLI deallocation workflows (`az aks stop`) to freeze physical VM billing during idle periods while preserving master-plane state and etcd disk storage.
- **Cost Protection:** Complete automated environment lifecycle enabling full cluster teardown and redeployment in under 5 minutes via modular Bicep templates.

---

## 📂 Repository Structure


```

azure-multi-region-dr-platform/
├── .github/
│   └── workflows/
│       └── bicep-lint.yml           # CI workflow for IaC linting and ARM validation
├── infra/
│   ├── main.bicep                   # Subscription & Resource Group orchestrator
│   ├── parameters.json              # Parameter configuration (Sanitized for Git)
│   └── modules/
│       ├── aks-cluster.bicep        # AKS & Node Pool definition
│       ├── networking.bicep         # VNets, Subnets, and NSGs
│       └── monitoring.bicep         # Action Groups, Activity Log Alerts, Slack webhook
├── k8s/
│   ├── 01-namespace.yaml            # Isolated production workloads
│   ├── 02-app-deployment.yaml       # Container deployment specification
│   └── 03-ingress-service.yaml      # Public routing & Health probe endpoint
└── README.md                        # Architecture documentation & operations guide

```

---

## 🛠️ Infrastructure as Code (IaC) Deployment

### Prerequisites
- [Azure CLI installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az version` >= 2.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Active Azure Subscription (Free Tier / Pay-As-You-Go)

### 1. Clone the Repository
```bash
git clone [https://github.com/jaimindevops/azure-multi-region-dr-platform.git](https://github.com/jaimindevops/azure-multi-region-dr-platform.git)
cd azure-multi-region-dr-platform

```

### 2. Deploy Infrastructure via Bicep

```bash
# Log in to Azure
az login

# Deploy core resource groups and monitoring infrastructure
az deployment sub create \\
  --location eastus \\
  --template-file infra/main.bicep \\
  --parameters @infra/parameters.json

```

---

## 🧪 Operational Runbook & Disaster Recovery Simulation

### Step 1: Start Both Regional Clusters

```bash
az aks start --resource-group rg-dr-primary-eastus --name aks-primary-eastus --no-wait
az aks start --resource-group rg-dr-secondary-westus --name aks-secondary-westus --no-wait

```

### Step 2: Verify Baseline Traffic Manager Routing

```bash
# Inspect endpoint health status
az network traffic-manager profile show \\
  --resource-group rg-dr-primary-eastus \\
  --name tm-global-llmops \\
  --query "endpoints[*].{Name:name, Priority:priority, Target:target, Status:endpointMonitorStatus}" \\
  --output table

# Verify DNS resolution points to Primary (East US)
nslookup tm-global-llmops-18.trafficmanager.net

```

### Step 3: Simulate Regional Outage (Failover Test)

```bash
# Shut down Primary Region AKS Cluster
az aks stop --resource-group rg-dr-primary-eastus --name aks-primary-eastus --output table

```

**Expected Results:**

1. **ChatOps Alert Triggered:** Azure Monitor captures the `stop/action` event and dispatches real-time cards to the `#all-cloud-defense` Slack channel and email inbox.
2. **Automated DNS Shift:** Traffic Manager detects the degraded status of Endpoint 1 and switches DNS routing to `aks-secondary-westus` (Priority 2).

---

## 🛡️ FinOps Clean-up & Cost Management

To guarantee zero ongoing compute leakage against promotional account quotas:

```bash
# 1. Stop active compute (Zero compute burn, maintains storage & configs)
az aks stop --resource-group rg-dr-primary-eastus --name aks-primary-eastus --no-wait
az aks stop --resource-group rg-dr-secondary-westus --name aks-secondary-westus --no-wait

# 2. Complete Environment Teardown (Full clean slate)
az group delete --name rg-dr-primary-eastus --yes --no-wait
az group delete --name rg-dr-secondary-westus --yes --no-wait

```

---

## 🎓 AZ-104 Exam & Industry Competencies Demonstrated

| Exam Domain | Real-World Implementation in this Project |
| --- | --- |
| **Manage Identities & Governance** | Entra ID RBAC assignments, secure parameter injection (`@secure()`). |
| **Implement & Manage Storage** | Geo-replicated Azure Container Registry (ACR Premium) with multi-region synchronization. |
| **Deploy & Manage Compute** | Managed Kubernetes (AKS), Node Pool lifecycle management, cluster start/stop APIs. |
| **Configure & Manage Virtual Networks** | Custom Multi-Region VNet peering, subnet segregation, Azure Traffic Manager DNS routing. |
| **Monitor & Maintain Azure Resources** | Azure Monitor Action Groups, Activity Log Alert Rules, ChatOps Slack integration. |

---

## 👤 Author

* **GitHub:** [[@jaimindevops](https://www.google.com/search?q=https://github.com/jaimindevops)](https://github.com/jaimindevops)
