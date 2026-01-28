<p align="center">
  <img src="scaf-logo.png" width="250px">
</p>

**scaf-talos-template** provides DevOps engineers and infrastructure teams with a complete blueprint for deploying production-ready Talos Linux Kubernetes clusters on AWS.

This template generates infrastructure-as-code for a secure, immutable Kubernetes cluster using Talos Linux. A new project contains the following:

- **Talos Linux v1.12.1** - Immutable, secure Kubernetes OS
- **Terraform/OpenTofu** - Infrastructure provisioning for AWS
- **AWS Infrastructure** - VPC, EC2, security groups, load balancers, Route53
- **Multi-Environment Support** - Sandbox, staging, and production configurations
- **Bootstrap Scripts** - Automated Talos cluster initialization
- **GitHub Actions** - Infrastructure validation and security scanning
- **Comprehensive Documentation** - Deployment guides and architecture diagrams

## What is Talos Linux?

Talos Linux is a modern, minimal Linux distribution designed specifically for running Kubernetes:

- **Immutable** - No SSH access, configuration via API only
- **Secure** - Minimal attack surface, all management via encrypted API
- **Kubernetes-Native** - Built exclusively for Kubernetes workloads
- **API-Driven** - All operations performed via declarative configuration

## Installation

To create a new project using this template, you first need to install `scaf`:

```bash
curl -sSL https://raw.githubusercontent.com/sixfeetup/scaf/main/install.sh | bash
```

## Creating a new project using this template

Run the following command to create a new project:

```bash
# If you have the template checked out locally:
scaf myproject ./scaf-talos-template

# Or use the GitHub URL directly:
scaf myproject https://github.com/getscaf/scaf-talos-template.git
```

Answer all the questions, and you'll have your new Talos cluster infrastructure project!

After creating the project, you need to bootstrap the infrastructure.

First, make sure you're logged in to AWS:

```bash
export AWS_PROFILE=profile && aws sso login
```

Then proceed with the infrastructure setup:

```bash
# 1. Create the S3 backend for Terraform state
cd myproject/terraform/bootstrap
tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out

# 2. Deploy the infrastructure - sandbox environment
cd ../sandbox
tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out

# 3. Bootstrap Talos cluster
cd ../../bootstrap-cluster
export ENV=sandbox
task talos:bootstrap

# 4. Access your cluster
eval $(task talos:kubeconfig)
kubectl get nodes
```

**Note:** The sandbox environment creates a **1-node cluster** for development and testing. For staging and production environments with **3-node clusters**, use:

```bash
# Deploy staging (3 nodes)
cd terraform/staging
tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out
cd ../../bootstrap-cluster
export ENV=staging
task talos:bootstrap

# Deploy production (3 nodes)
cd ../terraform/production
tofu init && tofu plan -out=tfplan.out && tofu apply tfplan.out
cd ../../bootstrap-cluster
export ENV=production
task talos:bootstrap
```

Inside `myproject/docs/`, you will find comprehensive documentation for:
- Deploying infrastructure to AWS
- Bootstrapping the Talos cluster
- Managing cluster credentials
- Architecture diagrams

## Requirements

- AWS account with appropriate credentials
- Terraform/OpenTofu (v1.6+)
- talosctl CLI
- kubectl CLI
- Task runner

See the generated documentation for detailed prerequisites.

## Removing an Environment

To completely remove an environment and all its resources:


```bash
# 1. Destroy the infrastructure
cd myproject/terraform/sandbox  # or staging, production
tofu destroy

# 2. Clean up local configuration files
cd ../../bootstrap-cluster/sandbox  # or staging, production
rm -f talosconfig kubeconfig controlplane.yaml

# 3. (Optional) Remove secrets from AWS Secrets Manager
aws secretsmanager delete-secret --secret-id sandbox_talos_controlplane_yaml --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id sandbox_kubeconfig --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id sandbox_talosconfig_yaml --force-delete-without-recovery
```

For complete removal instructions, including how to destroy the S3 backend, see the [Deployment Documentation](myproject/docs/deployment.md).
