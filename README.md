# kube-labs



📜 Script Overview & Explanation

This script automates the creation of a local Kubernetes platform with advanced networking, observability, and traffic management capabilities. It is designed as a cloud-native lab and reference environment that closely resembles production-grade Kubernetes setups.

The automation follows a layered platform approach:

Kubernetes cluster provisioning

Networking and dataplane (Cilium + eBPF)

Network observability (Hubble)

Metrics and monitoring (Prometheus & Grafana)

Traffic management (Gateway API)

Health validation and readiness checks

🧱 Step-by-Step Breakdown
1️⃣ Kubernetes Cluster Provisioning (Kind)

Creates a Kind-based Kubernetes cluster

Uses a pinned Kubernetes node image (v1.35.0) for reproducibility

Supports a custom Kind configuration file

Ensures a consistent local environment for testing advanced Kubernetes features

Purpose:
Provide a lightweight but realistic Kubernetes environment suitable for networking and platform experiments.

2️⃣ Cilium & Hubble CLI Installation

Automatically downloads the latest stable versions of:

cilium CLI

hubble CLI

Verifies binaries using SHA256 checksums

Detects system architecture (amd64 / arm64)

Installs tools system-wide for cluster management

Purpose:
Enable management, troubleshooting, and observability of the Cilium dataplane.

3️⃣ Cilium CNI Deployment

Cilium is installed as the primary Kubernetes networking layer with advanced features enabled:

kube-proxy replacement (eBPF-based service handling)

BGP Control Plane for advanced routing scenarios

Gateway API support for modern traffic management

Layer 7 (L7) proxying

Prometheus metrics exposure

Hubble (Relay + UI) for network observability

Purpose:
Replace traditional kube-proxy and iptables with a high-performance, eBPF-powered dataplane suitable for modern cloud-native platforms.

4️⃣ Cluster & Cilium Health Validation

The script continuously checks:

Kubernetes node readiness

Cilium agent pod status in kube-system

The process blocks until:

All nodes are Ready

All Cilium components are Running

Purpose:
Ensure networking is fully functional before deploying higher-level platform services.

5️⃣ Observability Stack (kube-prometheus-stack)

Deploys a production-grade monitoring stack into a dedicated namespace:

Prometheus (metrics collection)

Grafana (visualization)

Alertmanager (alerting)

Key characteristics:

Helm-based installation

Version pinned for consistency

Secure output logging

Namespace isolation (monitor)

Purpose:
Provide deep visibility into cluster health, networking, and Cilium metrics.

6️⃣ Monitoring Readiness Validation

The script waits until monitoring components are running successfully before proceeding.

Purpose:
Guarantee that observability is available before enabling traffic and gateway features.

7️⃣ Gateway API Installation

Installs Gateway API CRDs using server-side apply

Validates installation using Kubernetes API introspection

Purpose:
Enable modern Kubernetes traffic management that goes beyond Ingress, aligning with cloud-provider and service mesh patterns.

8️⃣ Final Cilium Status Verification

Runs cilium status --wait

Confirms:

Cilium agents

Operators

Hubble components

Dataplane readiness

Purpose:
Provide a final, authoritative validation that the networking platform is fully operational.

🏗️ Architecture Summary
Local Machine
 └── Kind Kubernetes Cluster
      ├── Cilium (eBPF Dataplane)
      │    ├── kube-proxy replacement
      │    ├── BGP Control Plane
      │    ├── Gateway API
      │    ├── L7 Proxy
      │    └── Hubble Observability
      │
      ├── kube-prometheus-stack
      │    ├── Prometheus
      │    ├── Grafana
      │    └── Alertmanager
      │
      └── Gateway API CRDs



# manifist files

1- create 3 namespaces  and those are  monitor ,web,backup 
2- create  deployment   under  namespace web and  backup 
3- under namespace  monitor will deploy  all pods  of kube-promethemus-stack  for  visibility to all  nodes and pods along with  traffic flow 
4- exposing  pods under namespace  web and backup  using service  NodePort for deployment 
5- create  hpa[ horizontal pod autoscaler]  for  deployment that  reside at  web and  backup namespaces 
6- access to grafana  to check and  review  changes metrics and threshold related to  all nodes and pods 
