```markdown
# 🌐 Multi-Region Resilient Kubernetes DR & LLMOps Infrastructure on Azure

An enterprise-grade, budget-governed Multi-Region Active/Passive Disaster Recovery (DR) and LLMOps deployment on Microsoft Azure. Built with modular **Bicep Infrastructure as Code (IaC)**, **Azure Kubernetes Service (AKS)**, **Geo-Replicated Azure Container Registry (ACR Premium)**, **Azure Traffic Manager**, and a real-time **Multi-Channel Alerting Engine (Email + Slack)**.

---

## 🎯 Engineering Challenges Addressed

| Challenge Area | Traditional / Single-Region Pitfall | How This Architecture Solves It |
| :--- | :--- | :--- |
| **Single-Region Dependency** | Regional outages or data center connectivity failures cause complete service downtime (High RTO / RPO). | Implements an **Active/Passive Multi-Region Topology** (`East US` paired with `West US`) with **Azure Traffic Manager Priority Routing** that automatically shifts DNS traffic within seconds of primary node degradation. |
| **Cross-Region Latency & Image Pull Bottlenecks** | Standby clusters pulling large container/model images across geographical regions experience bandwidth throttling, higher egress costs, and cold-start delays. | Leverages **ACR Premium Geo-Replication**, asynchronously synchronizing container images across regions so local nodes pull images locally within the regional backbone network. |
| **Idle Standby Compute Waste (FinOps)** | Maintaining secondary standby clusters 24/7 doubles infrastructure costs. | Leverages **Azure AKS Node Pool Power State Management (`az aks stop / start`)** to deallocate physical VMs during steady state while preserving control-plane configurations and persistent volumes. |
| **Configuration Drift & Deployment Overhead** | Manual cloud setups introduce regional configuration discrepancies and slow recovery times during disasters. | Uses **Modular Bicep IaC** to provision identical Virtual Networks, Subnets, AKS Clusters, and Alerting pipelines across regions deterministically. |

---

## 🔍 Observability Gaps & Incident Response Solutions

In cloud incident response and site reliability engineering (SRE), traditional monitoring setups often suffer from major blind spots:

### 1. The Direct Webhook Silent Failure Gap
- **The Gap:** Sending raw Azure Monitor alerts directly to third-party endpoints (like Slack incoming webhooks) causes silent delivery failures (`HTTP 400 Bad Request`) because Azure delivers the rich **Common Alert Schema**, whereas standard webhooks expect simpler payload structures.
- **The Solution:** Implements **Action Groups with Inbound Channel Integration** (`DRAlerts`), ensuring 100% reliable alert delivery directly into engineer ChatOps channels (`#all-cloud-defense`) without requiring complex middleware.

### 2. Control-Plane Lifecycle Visibility
- **The Gap:** Application synthetic uptime tests only detect failures *after* user requests start timing out.
- **The Solution:** Azure Monitor **Activity Log Alert Rules (`alert-aks-primary-health`)** monitor ARM control-plane operations (`Microsoft.ContainerService/managedClusters/write` and `/stop/action`), triggering alerts the moment cluster state changes occur.

### 3. Dual-Channel Redundancy
- **The Solution:** Alerts are dispatched simultaneously to **Tier-1 Engineering Email** and **Real-Time Slack ChatOps**, preventing single points of communication failure during off-hours incidents.

---

## 🏛️ High-Level System Architecture

https://github.com/jaimindevops/azure-multi-region-dr-platform/blob/main/High_Level_Architecture/Architecture.png?raw=true
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
    │     (admin-alert)         │   │     (#all-cloud-defense)  │
    └───────────────────────────┘   └───────────────────────────┘

```

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
  1. **Tier-1 Admin Email:** Direct escalation inbox (`admin-alert`).
  2. **Slack ChatOps:** Dedicated incident response channel (`#all-cloud-defense`).

### 4. 💰 FinOps & Strict Governance
- **Zero-Idle Compute Policy:** Implements Azure CLI deallocation workflows (`az aks stop`) to freeze physical VM billing during idle periods while preserving master-plane state and etcd disk storage.
- **Cost Protection:** Complete automated environment lifecycle enabling full cluster teardown and redeployment in under 5 minutes via modular Bicep templates.

---

## 📂 Repository Structure

<img width="822" height="357" alt="image" src="https://github.com/user-attachments/assets/8717d26a-7611-438d-8a81-1958f56d53dc" />


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
- Active Azure Subscription

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
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
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
az network traffic-manager profile show \
  --resource-group rg-dr-primary-eastus \
  --name tm-global-llmops \
  --query "endpoints[*].{Name:name, Priority:priority, Target:target, Status:endpointMonitorStatus}" \
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

To guarantee zero ongoing compute leakage:

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

* **GitHub:** [@jaimindevops](https://www.google.com/search?q=https://github.com/jaimindevops)

```

---

### 💻 Quick Command to Update and Push to GitHub

Run this single command in your **macOS Terminal**:

```bash
cat << 'EOF' > README.md
# 🌐 Multi-Region Resilient Kubernetes DR & LLMOps Infrastructure on Azure

[![Azure](https://img.shields.io/badge/Azure-AZ--104%20Certified%20Architecture-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS%20Multi--Region-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![IaC](https://img.shields.io/badge/IaC-Bicep%20Modular-0089D6?logo=azuredevops&logoColor=white)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
[![FinOps](https://img.shields.io/badge/FinOps-Zero--Idle%20Cost%20Governed-green?logo=azure&logoColor=white)](https://www.finops.org/)
[![Observability](https://img.shields.io/badge/Observability-Azure%20Monitor%20%7C%20Slack-4A154B?logo=slack&logoColor=white)](https://slack.com/)

An enterprise-grade, budget-governed Multi-Region Active/Passive Disaster Recovery (DR) and LLMOps deployment on Microsoft Azure. Built with modular **Bicep Infrastructure as Code (IaC)**, **Azure Kubernetes Service (AKS)**, **Geo-Replicated Azure Container Registry (ACR Premium)**, **Azure Traffic Manager**, and a real-time **Multi-Channel Alerting Engine (Email + Slack)**.

---

## 🎯 Engineering Challenges Addressed

| Challenge Area | Traditional / Single-Region Pitfall | How This Architecture Solves It |
| :--- | :--- | :--- |
| **Single-Region Dependency** | Regional outages or data center connectivity failures cause complete service downtime (High RTO / RPO). | Implements an **Active/Passive Multi-Region Topology** (`East US` paired with `West US`) with **Azure Traffic Manager Priority Routing** that automatically shifts DNS traffic within seconds of primary node degradation. |
| **Cross-Region Latency & Image Pull Bottlenecks** | Standby clusters pulling large container/model images across geographical regions experience bandwidth throttling, higher egress costs, and cold-start delays. | Leverages **ACR Premium Geo-Replication**, asynchronously synchronizing container images across regions so local nodes pull images locally within the regional backbone network. |
| **Idle Standby Compute Waste (FinOps)** | Maintaining secondary standby clusters 24/7 doubles infrastructure costs. | Leverages **Azure AKS Node Pool Power State Management (`az aks stop / start`)** to deallocate physical VMs during steady state while preserving control-plane configurations and persistent volumes. |
| **Configuration Drift & Deployment Overhead** | Manual cloud setups introduce regional configuration discrepancies and slow recovery times during disasters. | Uses **Modular Bicep IaC** to provision identical Virtual Networks, Subnets, AKS Clusters, and Alerting pipelines across regions deterministically. |

---

## 🔍 Observability Gaps & Incident Response Solutions

In cloud incident response and site reliability engineering (SRE), traditional monitoring setups often suffer from major blind spots:

### 1. The Direct Webhook Silent Failure Gap
- **The Gap:** Sending raw Azure Monitor alerts directly to third-party endpoints (like Slack incoming webhooks) causes silent delivery failures (`HTTP 400 Bad Request`) because Azure delivers the rich **Common Alert Schema**, whereas standard webhooks expect simpler payload structures.
- **The Solution:** Implements **Action Groups with Inbound Channel Integration** (`DRAlerts`), ensuring 100% reliable alert delivery directly into engineer ChatOps channels (`#all-cloud-defense`) without requiring complex middleware.

### 2. Control-Plane Lifecycle Visibility
- **The Gap:** Application synthetic uptime tests only detect failures *after* user requests start timing out.
- **The Solution:** Azure Monitor **Activity Log Alert Rules (`alert-aks-primary-health`)** monitor ARM control-plane operations (`Microsoft.ContainerService/managedClusters/write` and `/stop/action`), triggering alerts the moment cluster state changes occur.

### 3. Dual-Channel Redundancy
- **The Solution:** Alerts are dispatched simultaneously to **Tier-1 Engineering Email** and **Real-Time Slack ChatOps**, preventing single points of communication failure during off-hours incidents.

---

## 🏛️ High-Level System Architecture

<img width="748" height="376" alt="image" src="https://github.com/user-attachments/assets/0c055c35-fafc-4d04-9cab-f62e1d963365" />


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
    │     (admin-alert)         │   │     (#all-cloud-defense)  │
    └───────────────────────────┘   └───────────────────────────┘

```

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
  1. **Tier-1 Admin Email:** Direct escalation inbox (`admin-alert`).
  2. **Slack ChatOps:** Dedicated incident response channel (`#all-cloud-defense`).

### 4. 💰 FinOps & Strict Governance
- **Zero-Idle Compute Policy:** Implements Azure CLI deallocation workflows (`az aks stop`) to freeze physical VM billing during idle periods while preserving master-plane state and etcd disk storage.
- **Cost Protection:** Complete automated environment lifecycle enabling full cluster teardown and redeployment in under 5 minutes via modular Bicep templates.

---

## 📂 Repository Structure

<img width="822" height="357" alt="image" src="https://github.com/user-attachments/assets/8717d26a-7611-438d-8a81-1958f56d53dc" />


```
<img width="709" height="339" alt="image" src="https://github.com/user-attachments/assets/9f35a1a1-42b1-4cd2-a6c3-d1cad9717765" />

```

---

## 🛠️ Infrastructure as Code (IaC) Deployment

### Prerequisites
- [Azure CLI installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az version` >= 2.50.0)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Active Azure Subscription

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
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
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
az network traffic-manager profile show \
  --resource-group rg-dr-primary-eastus \
  --name tm-global-llmops \
  --query "endpoints[*].{Name:name, Priority:priority, Target:target, Status:endpointMonitorStatus}" \
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

To guarantee zero ongoing compute leakage:

```bash
# 1. Stop active compute (Zero compute burn, maintains storage & configs)
az aks stop --resource-group rg-dr-primary-eastus --name aks-primary-eastus --no-wait
az aks stop --resource-group rg-dr-secondary-westus --name aks-secondary-westus --no-wait

# 2. Complete Environment Teardown (Full clean slate)
az group delete --name rg-dr-primary-eastus --yes --no-wait
az group delete --name rg-dr-secondary-westus --yes --no-wait

```
---

[![Azure](https://img.shields.io/badge/Azure-AZ--104%20Certified%20Architecture-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS%20Multi--Region-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![IaC](https://img.shields.io/badge/IaC-Bicep%20Modular-0089D6?logo=azuredevops&logoColor=white)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
[![FinOps](https://img.shields.io/badge/FinOps-Zero--Idle%20Cost%20Governed-green?logo=azure&logoColor=white)](https://www.finops.org/)
[![Observability](https://img.shields.io/badge/Observability-Azure%20Monitor%20%7C%20Slack-4A154B?logo=slack&logoColor=white)](https://slack.com/)

---
## 👤 Author

* **GitHub:** (https://github.com/jaimindevops)
