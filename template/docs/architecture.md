# :house: Architecture

This document outlines the infrastructure architecture for deploying Talos Linux Kubernetes clusters on AWS.

## System Overview

The template provides infrastructure for deploying a Talos Linux Kubernetes cluster with the following components:

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#282828',
      'primaryTextColor': '#ebdbb2',
      'primaryBorderColor': '#7c6f64',
      'lineColor': '#7c6f64',
      'secondaryColor': '#3c3836',
      'tertiaryColor': '#504945'
    }
  }
}%%
flowchart TD
    subgraph SystemOverview["Talos Cluster Architecture"]
        subgraph InfraLayer["Infrastructure Layer"]
            TF[Terraform/OpenTofu] --> AWS[AWS Resources]
            AWS --> VPC[VPC Network]
            AWS --> EC2[EC2 Instances]
            AWS --> DNS[Route53 DNS]
        end

        subgraph OSLayer["Operating System Layer"]
            EC2 --> TALOS[Talos Linux v1.12.1]
            TALOS --> API[Talos API]
        end

        subgraph K8sLayer["Kubernetes Layer"]
            API --> K8S[Kubernetes Cluster]
            K8S --> CP[Control Plane]
            CP --> APISERVER[API Server]
            CP --> ETCD[etcd]
            CP --> SCHEDULER[Scheduler]
        end
    end

    %% Style definitions - Gruvbox Dark theme
    classDef infrastructure fill:#d79921,stroke:#b57614,stroke-width:2px,color:#282828,font-weight:bold
    classDef os fill:#689d6a,stroke:#427b58,stroke-width:2px,color:#282828,font-weight:bold
    classDef kubernetes fill:#458588,stroke:#076678,stroke-width:2px,color:#282828,font-weight:bold

    %% Apply styles
    class TF,AWS,VPC,EC2,DNS infrastructure
    class TALOS,API os
    class K8S,CP,APISERVER,ETCD,SCHEDULER kubernetes

    %% Explicit styling for subgraphs
    style SystemOverview fill:#282828,color:#fabd2f,font-weight:bold
    style InfraLayer fill:#282828,color:#fabd2f,font-weight:bold
    style OSLayer fill:#282828,color:#fabd2f,font-weight:bold
    style K8sLayer fill:#282828,color:#fabd2f,font-weight:bold
```

## AWS Infrastructure (Terraform)

The cloud infrastructure is managed with Terraform/OpenTofu, provisioning the following AWS resources:

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#282828',
      'primaryTextColor': '#ebdbb2',
      'primaryBorderColor': '#7c6f64',
      'lineColor': '#7c6f64',
      'secondaryColor': '#3c3836',
      'tertiaryColor': '#504945'
    }
  }
}%%
flowchart TB
    INTERNET([Internet])

    subgraph AWSArch["AWS Infrastructure"]
        R53[Route53 DNS] --> ELB[Elastic Load Balancer]

        ELB --> VPC[VPC Network]

        VPC --> SG[Security Groups]
        VPC --> SUBNET[Public Subnets]

        SUBNET --> EC2_1[EC2 Control Plane 1<br/>Talos Linux]
        SUBNET --> EC2_2[EC2 Control Plane 2<br/>Talos Linux]
        SUBNET --> EC2_3[EC2 Control Plane 3<br/>Talos Linux]

        SG --> EC2_1
        SG --> EC2_2
        SG --> EC2_3

        IAM[IAM Roles] --> EC2_1
        IAM --> EC2_2
        IAM --> EC2_3
    end

    INTERNET --> |k8s.domain.com:6443| R53

    %% Style definitions - Gruvbox Dark theme
    classDef external fill:#3c3836,stroke:#928374,stroke-width:1px,color:#ebdbb2,font-weight:bold
    classDef network fill:#d79921,stroke:#b57614,stroke-width:2px,color:#282828,font-weight:bold
    classDef compute fill:#689d6a,stroke:#427b58,stroke-width:2px,color:#282828,font-weight:bold
    classDef security fill:#458588,stroke:#076678,stroke-width:2px,color:#282828,font-weight:bold

    %% Apply styles
    class INTERNET external
    class R53,ELB,VPC,SUBNET network
    class EC2_1,EC2_2,EC2_3 compute
    class SG,IAM security

    %% Explicit styling for subgraph
    style AWSArch fill:#282828,color:#fabd2f,font-weight:bold
```

### Infrastructure Components

- **VPC**: Isolated network with configurable CIDR blocks
- **Public Subnets**: Subnets across multiple availability zones for high availability
- **Security Groups**: Firewall rules for Kubernetes API (6443), Talos API (50000), and inter-node communication
- **EC2 Instances**: Control plane nodes running Talos Linux AMI
- **Elastic Load Balancer**: Load balances traffic to control plane nodes
- **Route53**: DNS records for cluster API endpoint (k8s.domain.com)
- **IAM Roles**: Permissions for EC2 instances to access AWS services

## Talos Linux Architecture

Talos Linux provides the operating system layer that creates and manages the Kubernetes cluster:

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#282828',
      'primaryTextColor': '#ebdbb2',
      'primaryBorderColor': '#7c6f64',
      'lineColor': '#7c6f64',
      'secondaryColor': '#3c3836',
      'tertiaryColor': '#504945'
    }
  }
}%%
flowchart TB
    ADMIN([Cluster Administrator])

    subgraph TalosArch["Talos Linux Architecture"]
        TALOSCTL[talosctl CLI] --> |gRPC/TLS| TALOSAPI[Talos API :50000]

        TALOSAPI --> MACHINED[machined<br/>System Service Manager]

        MACHINED --> K8S_SERVICES[Kubernetes Services]
        MACHINED --> SYSTEM[System Services]

        K8S_SERVICES --> KUBELET[kubelet]
        K8S_SERVICES --> API_SERVER[kube-apiserver]
        K8S_SERVICES --> CONTROLLER[kube-controller-manager]
        K8S_SERVICES --> SCHEDULER[kube-scheduler]
        K8S_SERVICES --> ETCD[etcd]

        SYSTEM --> NETWORKD[networkd<br/>Network Management]
        SYSTEM --> TRUSTD[trustd<br/>Certificate Management]
    end

    ADMIN --> TALOSCTL

    KUBECTL[kubectl] --> |HTTPS:6443| API_SERVER

    %% Style definitions - Gruvbox Dark theme
    classDef external fill:#3c3836,stroke:#928374,stroke-width:1px,color:#ebdbb2,font-weight:bold
    classDef api fill:#d79921,stroke:#b57614,stroke-width:2px,color:#282828,font-weight:bold
    classDef core fill:#689d6a,stroke:#427b58,stroke-width:2px,color:#282828,font-weight:bold
    classDef k8s fill:#458588,stroke:#076678,stroke-width:2px,color:#282828,font-weight:bold
    classDef system fill:#cc241d,stroke:#9d0006,stroke-width:2px,color:#282828,font-weight:bold

    %% Apply styles
    class ADMIN,TALOSCTL,KUBECTL external
    class TALOSAPI api
    class MACHINED,K8S_SERVICES,SYSTEM core
    class KUBELET,API_SERVER,CONTROLLER,SCHEDULER,ETCD k8s
    class NETWORKD,TRUSTD system

    %% Explicit styling for subgraph
    style TalosArch fill:#282828,color:#fabd2f,font-weight:bold
```

### Talos Components

- **machined**: Core system service that manages all other services
- **Talos API**: gRPC API for cluster management (port 50000)
- **kubelet**: Kubernetes node agent
- **kube-apiserver**: Kubernetes API server (port 6443)
- **kube-controller-manager**: Kubernetes controller manager
- **kube-scheduler**: Kubernetes scheduler
- **etcd**: Distributed key-value store for Kubernetes state
- **networkd**: Network configuration and management
- **trustd**: Certificate and PKI management

## Deployment Flow

This diagram shows the deployment process from infrastructure provisioning to running cluster:

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#282828',
      'primaryTextColor': '#ebdbb2',
      'primaryBorderColor': '#7c6f64',
      'lineColor': '#7c6f64',
      'secondaryColor': '#3c3836',
      'tertiaryColor': '#504945'
    }
  }
}%%
flowchart LR
    subgraph DeployFlow["Deployment Flow"]
        TERRAFORM[1. Terraform Apply<br/>Provision AWS Resources] --> EC2[2. EC2 Instances Boot<br/>Talos Linux AMI]
        EC2 --> GENCONFIG[3. Generate Configs<br/>talosctl gen config]
        GENCONFIG --> APPLYCONFIG[4. Apply Configuration<br/>talosctl apply-config]
        APPLYCONFIG --> BOOTSTRAP[5. Bootstrap Cluster<br/>talosctl bootstrap]
        BOOTSTRAP --> KUBECONFIG[6. Generate kubeconfig<br/>talosctl kubeconfig]
        KUBECONFIG --> RUNNING[7. Cluster Running<br/>kubectl get nodes]
    end

    %% Style definitions - Gruvbox Dark theme
    classDef terraform fill:#d79921,stroke:#b57614,stroke-width:2px,color:#282828,font-weight:bold
    classDef boot fill:#689d6a,stroke:#427b58,stroke-width:2px,color:#282828,font-weight:bold
    classDef config fill:#458588,stroke:#076678,stroke-width:2px,color:#282828,font-weight:bold
    classDef running fill:#cc241d,stroke:#9d0006,stroke-width:2px,color:#282828,font-weight:bold

    %% Apply styles
    class TERRAFORM terraform
    class EC2 boot
    class GENCONFIG,APPLYCONFIG,BOOTSTRAP,KUBECONFIG config
    class RUNNING running

    %% Explicit styling for subgraph
    style DeployFlow fill:#282828,color:#fabd2f,font-weight:bold
```

## Environment Architecture

The project supports multiple environments with different configurations:

```mermaid
%%{
  init: {
    'theme': 'base',
    'themeVariables': {
      'primaryColor': '#282828',
      'primaryTextColor': '#ebdbb2',
      'primaryBorderColor': '#7c6f64',
      'lineColor': '#7c6f64',
      'secondaryColor': '#3c3836',
      'tertiaryColor': '#504945'
    }
  }
}%%
flowchart TB
    subgraph EnvArch["Environment Architecture"]
        TERRAFORM[Terraform Base Module]

        TERRAFORM --> SANDBOX[Sandbox Environment<br/>terraform/sandbox/]
        TERRAFORM --> STAGING[Staging Environment<br/>terraform/staging/]
        TERRAFORM --> PROD[Production Environment<br/>terraform/production/]

        SANDBOX --> SANDBOX_CLUSTER[Talos Cluster<br/>k8s.sandbox.domain.com]
        STAGING --> STAGING_CLUSTER[Talos Cluster<br/>k8s.staging.domain.com]
        PROD --> PROD_CLUSTER[Talos Cluster<br/>k8s.prod.domain.com]
    end

    %% Style definitions - Gruvbox Dark theme
    classDef base fill:#458588,stroke:#076678,stroke-width:2px,color:#282828,font-weight:bold
    classDef sandbox fill:#b16286,stroke:#8f3f71,stroke-width:2px,color:#282828,font-weight:bold
    classDef staging fill:#d79921,stroke:#b57614,stroke-width:2px,color:#282828,font-weight:bold
    classDef prod fill:#cc241d,stroke:#9d0006,stroke-width:2px,color:#282828,font-weight:bold
    classDef cluster fill:#689d6a,stroke:#427b58,stroke-width:2px,color:#282828,font-weight:bold

    %% Apply styles
    class TERRAFORM base
    class SANDBOX sandbox
    class STAGING staging
    class PROD prod
    class SANDBOX_CLUSTER,STAGING_CLUSTER,PROD_CLUSTER cluster

    %% Explicit styling for subgraph
    style EnvArch fill:#282828,color:#fabd2f,font-weight:bold
```

## Security Architecture

Talos Linux provides multiple layers of security:

1. **No SSH Access**: Impossible to SSH into nodes, eliminating a major attack vector
2. **Immutable File System**: Root filesystem is read-only and cannot be modified
3. **API Authentication**: All management operations require mutual TLS authentication
4. **Minimal Attack Surface**: Only runs Kubernetes components, nothing else
5. **Encrypted Communication**: All API communication is encrypted
6. **Certificate Management**: Automatic certificate rotation and management

## Network Architecture

Default ports and protocols:

- **6443**: Kubernetes API server (HTTPS)
- **50000**: Talos API (gRPC/TLS)
- **50001**: Talos Trustd API (gRPC/TLS)
- **2379-2380**: etcd client and peer communication
- **10250**: kubelet API

All inter-node communication is secured with TLS.
