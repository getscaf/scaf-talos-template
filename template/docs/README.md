# Talos Kubernetes Cluster Documentation

This directory contains documentation for deploying and managing a Talos Linux Kubernetes cluster on AWS.

## Overview

This project provides infrastructure-as-code templates for deploying a production-ready Talos Linux Kubernetes cluster on AWS using Terraform and OpenTofu.

## Documentation Contents

- **[Project Overview](./project-overview.md)** - Introduction to the template and its purpose
- **[Architecture](./architecture.md)** - Infrastructure architecture and design
- **[Deployment](./deployment.md)** - Step-by-step deployment instructions
- **[Secrets Management](./secrets.md)** - How to manage sensitive configuration

## What is Talos Linux?

Talos Linux is a modern, minimal Linux distribution designed specifically for running Kubernetes. Key features:

- **Immutable**: No SSH, no shell, configuration via API only
- **Secure**: Minimal attack surface, all management via encrypted API
- **Kubernetes-Native**: Built exclusively for running Kubernetes workloads
- **API-Driven**: All operations performed via declarative configuration

## Quick Start

1. Generate a new project from this template using Copier
2. Configure AWS credentials
3. Deploy infrastructure: `cd terraform/sandbox && tofu apply`
4. Bootstrap Talos cluster: `cd bootstrap-cluster/sandbox && task talos:bootstrap`
5. Access your cluster: `kubectl --kubeconfig kubeconfig get nodes`

For detailed instructions, see the [Deployment Documentation](./deployment.md).
