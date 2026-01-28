# :package: How to Deploy a Talos Cluster

This guide walks through deploying a Talos Linux Kubernetes cluster on AWS, from infrastructure provisioning to cluster bootstrap.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- **AWS CLI** - Configured with appropriate credentials
- **Terraform/OpenTofu** - Infrastructure provisioning (v1.6+)
- **talosctl** - Talos cluster management CLI
- **kubectl** - Kubernetes command-line tool
- **Task** - Task runner for automation

## Deployment Overview

The deployment process consists of two main phases:

1. **Infrastructure Provisioning** - Use Terraform to create AWS resources
2. **Cluster Bootstrap** - Use Talos to initialize the Kubernetes cluster

## Step 1: Configure AWS Credentials

Ensure your AWS credentials are configured:

```bash
aws configure
# OR
export AWS_PROFILE=your-profile
```

Verify access:

```bash
aws sts get-caller-identity
```

## Step 2: Choose Your Environment

The template supports three environments:

- **sandbox** - Testing and experimentation
- **staging** - Pre-production validation
- **production** - Production workloads

For this guide, we'll use **sandbox**. Replace with your chosen environment as needed.

## Step 3: Create S3 Backend for Terraform State

Before provisioning infrastructure, you need to create the S3 bucket and DynamoDB table for storing Terraform state.

Navigate to the bootstrap directory:

```bash
cd terraform/bootstrap
```

Initialize and apply the bootstrap configuration:

```bash
tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out
```

This creates:
- S3 bucket for storing Terraform state
- DynamoDB table for state locking

**Note:** This step only needs to be run once for all environments.

## Step 4: Provision Infrastructure with Terraform

### Initialize Terraform

Navigate to the environment directory:

```bash
cd ../sandbox
```

Initialize Terraform:

```bash
tofu init
```

### Review and Apply

Review the planned changes:

```bash
tofu plan
```

Apply the infrastructure:

```bash
tofu apply
```

Type `yes` when prompted to confirm.

### What Gets Created

Terraform provisions:

- VPC with public subnets across availability zones
- Security groups for Kubernetes and Talos APIs
- EC2 instances with Talos Linux AMI (control plane nodes)
- Elastic Load Balancer for control plane access
- Route53 DNS record for cluster API endpoint
- IAM roles for EC2 instances

**Note:** EC2 instances will boot with Talos OS but the Kubernetes cluster is NOT yet initialized.

## Step 5: Bootstrap the Talos Cluster

After infrastructure is provisioned, bootstrap the Kubernetes cluster.

### Navigate to Bootstrap Directory

```bash
cd ../../bootstrap-cluster/sandbox
```

### Review Environment Configuration

Check the `.env` file for your environment:

```bash
cat .env
```

This contains:
- `TALOS_FACTORY_IMAGE` - Talos version (v1.12.1)
- `TOFU_DIR` - Path to Terraform directory

### Run Bootstrap Process

Execute the bootstrap task:

```bash
export ENV=sandbox
task talos:bootstrap
```

This automated task performs the following steps:

1. **Generate Configs** - Creates `talosconfig` and `controlplane.yaml`
2. **Set Node IPs** - Configures Talos endpoints from Terraform output
3. **Apply Configuration** - Pushes Talos config to all nodes
4. **Bootstrap Kubernetes** - Initializes the Kubernetes cluster
5. **Generate kubeconfig** - Creates kubectl configuration
6. **Upgrade Talos** - Updates to specific v1.12.1 factory image

### Monitor the Process

You can monitor the bootstrap process via AWS Serial Console:

1. Go to AWS Console → EC2 → Instances
2. Select a control plane instance
3. Actions → Monitor and troubleshoot → Get system log

## Step 6: Verify Cluster Status

### Check Talos Node Health

```bash
export TALOSCONFIG=./sandbox/talosconfig
talosctl health --nodes <first-node-ip>
```

### Check Talos Version

```bash
talosctl version --nodes <node-ip>
```

### Access Kubernetes Cluster

```bash
export KUBECONFIG=./sandbox/kubeconfig
kubectl get nodes
```

Expected output:
```
NAME                 STATUS   ROLES           AGE   VERSION
my-cluster-0         Ready    control-plane   5m    v1.31.x
```



## Step 7: Store Credentials Securely

The bootstrap process stores credentials in AWS Secrets Manager:

- **Talosconfig** - Stored as `${ENV}_talosconfig_yaml`
- **Kubeconfig** - Stored as `${ENV}_kubeconfig`

Retrieve them later with:

```bash
# Get talosconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_talosconfig_yaml \
  --query SecretString --output text | base64 -d > talosconfig

# Get kubeconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_kubeconfig \
  --query SecretString --output text | base64 -d > kubeconfig
```

## Common Bootstrap Tasks

The `Taskfile.yml` in `bootstrap-cluster/` provides several useful tasks:

### List Available Tasks

```bash
task --list
```

### Individual Bootstrap Steps

If you need to run steps individually:

```bash
# Generate Talos configuration
task talos:generate_configs

# Apply config to nodes
task talos:apply_talos_config

# Bootstrap Kubernetes
task talos:bootstrap_kubernetes

# Generate kubeconfig
task talos:generate_kubeconfig

# Upgrade Talos version
task talos:upgrade_talos

# Check cluster health
task talos:health
```

## Upgrading Talos

To upgrade to a new Talos version:

1. Update `TALOS_FACTORY_IMAGE` in `bootstrap-cluster/.env`
2. Run the upgrade task:

```bash
export ENV=sandbox
task talos:upgrade_talos
```

## Managing Cluster Nodes

### Adding a Control Plane Node

This section describes how to add an additional control plane node to an existing cluster. The example uses the production environment.

**Prerequisites:**
- An existing, running cluster
- kubectl configured to access the cluster
- Terraform/OpenTofu installed

**Steps:**

1. Navigate to the environment directory:

```bash
cd terraform/production
```

2. Edit `cluster.tf` and add the new instance to the `control_plane.instances` map:

```terraform
control_plane = {
  instances = {
    "0" = {
      instance_type = "t3a.medium"
      disk_size     = 100
      subnet_index  = 0
    }
    "1" = {
      instance_type = "t3a.medium"
      disk_size     = 100
      subnet_index  = 1
    }
    "2" = {
      instance_type = "t3a.medium"
      disk_size     = 100
      subnet_index  = 2
    }
    "3" = {
      instance_type = "t3a.medium"
      disk_size     = 100
      subnet_index  = 0  # New node, reusing first AZ
    }
  }
}
```

3. Review the changes:

```bash
tofu plan
```

Terraform will show that it will create one new EC2 instance. Review the plan output carefully.

4. Apply the changes:

```bash
tofu apply
```

Type `yes` when prompted to confirm.

5. After the instance is created, retrieve the new node's IP address:

```bash
tofu output control_plane_nodes_public_ips
```

6. Configure Talos on the new node:

```bash
cd ../../bootstrap-cluster
export ENV=production
export TALOSCONFIG=./production/talosconfig

# Get the new node IP from the terraform output
NEW_NODE_IP=<new-node-ip>

# Apply the control plane configuration to the new node
# Note: --insecure is required for first-time configuration
talosctl apply-config --nodes $NEW_NODE_IP --file ./production/controlplane.yaml --insecure
```

7. Update the talosconfig to include the new node endpoint:

```bash
# Get all node IPs including the new one
ALL_IPS=$(cd ../terraform/production && tofu output -raw control_plane_nodes_public_ips | tr ',' ' ')

# Update talosconfig with all endpoints
talosctl --talosconfig ./production/talosconfig config endpoint $ALL_IPS
```

Verify the endpoints were updated:

```bash
talosctl --talosconfig ./production/talosconfig config info
```

8. Verify the new node has joined the cluster:

```bash
export KUBECONFIG=./production/kubeconfig
kubectl get nodes
```

The new node should appear in the node list.

9. Update the talosconfig in AWS Secrets Manager:

```bash
aws secretsmanager update-secret \
  --secret-id production_talosconfig_yaml \
  --secret-string "$(base64 -w0 ./production/talosconfig)"
```

This ensures the updated talosconfig (with the new node endpoint) is stored in AWS Secrets Manager for team access.

### Upgrading Instance Type

This section describes how to change the EC2 instance type for control plane nodes. The process upgrades one node at a time to maintain cluster availability.

**Prerequisites:**
- An existing, running cluster
- kubectl configured to access the cluster
- Terraform/OpenTofu installed

**Important:** For clusters with 3 nodes, etcd requires a quorum of 2 nodes. Upgrading one node at a time ensures the cluster remains operational.

**Steps for upgrading from t3a.medium to t3.large:**

1. Set up environment variables:

```bash
export KUBECONFIG=$(pwd)/bootstrap-cluster/production/kubeconfig
export TALOSCONFIG=$(pwd)/bootstrap-cluster/production/talosconfig
cd terraform/production
```

2. Drain the first node:

```bash
kubectl drain <cluster-name>-0 --ignore-daemonsets --delete-emptydir-data
```

This command safely evicts all pods from the node and marks it as unschedulable.

3. Edit `cluster.tf` and change the instance type for node 0:

```terraform
control_plane = {
  instances = {
    "0" = {
      instance_type = "t3.large"  # Changed from t3a.medium
      disk_size     = 100
      subnet_index  = 0
    }
    "1" = {
      instance_type = "t3a.medium"  # Unchanged
      disk_size     = 100
      subnet_index  = 1
    }
    "2" = {
      instance_type = "t3a.medium"  # Unchanged
      disk_size     = 100
      subnet_index  = 2
    }
  }
}
```

4. Apply the change to only the first node:

```bash
tofu apply -target='module.cluster.module.control_plane_nodes["0"]'
```

Review the plan. Terraform will destroy and recreate the instance with the new instance type. Type `yes` to confirm.

5. Wait for the node to boot and rejoin the cluster:

```bash
kubectl get nodes -w
```

Wait until the node status shows `Ready`. This typically takes 2-3 minutes.

6. Mark the node as schedulable again:

```bash
kubectl uncordon <cluster-name>-0
```

7. Verify cluster health:

```bash
kubectl get nodes
talosctl --nodes <node-ip> health
```

8. Repeat steps 2-7 for the remaining nodes, changing node 1 and then node 2:

For node 1:
```bash
kubectl drain <cluster-name>-1 --ignore-daemonsets --delete-emptydir-data
# Edit cluster.tf to change node "1" instance_type
tofu apply -target='module.cluster.module.control_plane_nodes["1"]'
kubectl get nodes -w
kubectl uncordon <cluster-name>-1
```

For node 2:
```bash
kubectl drain <cluster-name>-2 --ignore-daemonsets --delete-emptydir-data
# Edit cluster.tf to change node "2" instance_type
tofu apply -target='module.cluster.module.control_plane_nodes["2"]'
kubectl get nodes -w
kubectl uncordon <cluster-name>-2
```

9. Verify all nodes are running with the new instance type:

```bash
kubectl get nodes
```

All three nodes should show `Ready` status.

## Removing All Resources from an Environment

**WARNING:** This will permanently destroy all resources and data in the environment. This action cannot be undone.

### Step 1: Destroy the Environment Infrastructure

Navigate to the environment directory and destroy all resources:

```bash
cd terraform/sandbox  # or staging, production
tofu destroy
```

Review the resources that will be destroyed and type `yes` when prompted.

This will remove:
- EC2 instances (control plane nodes)
- Elastic Load Balancer
- Route53 DNS records
- Security groups
- VPC and subnets
- IAM roles

### Step 2: Clean Up Local Configuration Files

Remove the generated Talos and Kubernetes configuration files:

```bash
cd ../../bootstrap-cluster/sandbox  # or staging, production
rm -f talosconfig kubeconfig controlplane.yaml
```

### Step 3 (Optional): Remove Secrets from AWS Secrets Manager

If you want to remove the stored credentials:

```bash
aws secretsmanager delete-secret --secret-id sandbox_talosconfig_yaml --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id sandbox_kubeconfig --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id sandbox_talos_controlplane_yaml --force-delete-without-recovery
```

### Step 4 (Optional): Destroy S3 Backend

**WARNING:** Only do this if you want to remove ALL environments and start fresh. This will delete the Terraform state for all environments.

```bash
cd terraform/bootstrap
tofu destroy
```

This removes:
- S3 bucket storing Terraform state
- DynamoDB table for state locking

**Note:** You must destroy all environment infrastructure (sandbox, staging, production) before destroying the S3 backend.

