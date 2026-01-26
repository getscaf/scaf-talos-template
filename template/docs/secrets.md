# :shushing_face: How to Manage Cluster Credentials

This document describes how to manage sensitive cluster credentials for your Talos Kubernetes cluster.

## Cluster Credentials Overview

The Talos cluster has two primary credential files:

1. **talosconfig** - Used by `talosctl` to manage the Talos operating system
2. **kubeconfig** - Used by `kubectl` to interact with Kubernetes

Both files contain TLS certificates and keys that provide administrative access to the cluster.

## Automatic Storage in AWS Secrets Manager

During the bootstrap process (`task talos:bootstrap`), credentials are automatically stored in AWS Secrets Manager:

### Secrets Created

- **Talosconfig**: Stored as `${ENV}_talosconfig_yaml` (e.g., `sandbox_talosconfig_yaml`)
- **Kubeconfig**: Stored as `${ENV}_kubeconfig` (e.g., `sandbox_kubeconfig`)
- **Control Plane Config**: Stored as `${ENV}_controlplane_yaml`

These secrets are base64-encoded before storage.

## Retrieving Credentials

### From AWS Secrets Manager

Retrieve credentials from AWS Secrets Manager using the AWS CLI:

```bash
# Retrieve talosconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_talosconfig_yaml \
  --query SecretString --output text | base64 -d > talosconfig

# Retrieve kubeconfig
aws secretsmanager get-secret-value \
  --secret-id sandbox_kubeconfig \
  --query SecretString --output text | base64 -d > kubeconfig
```

### From Local Bootstrap Directory

After running `task talos:bootstrap`, credentials are also stored locally:

```bash
bootstrap-cluster/sandbox/
├── talosconfig       # Talos management credentials
├── kubeconfig        # Kubernetes access credentials
└── controlplane.yaml # Control plane configuration
```

## Using Credentials

### Using talosctl

Set the `TALOSCONFIG` environment variable:

```bash
export TALOSCONFIG=./bootstrap-cluster/sandbox/talosconfig

# Check Talos version
talosctl version --nodes <node-ip>

# View cluster health
talosctl health --nodes <node-ip>

# List all services
talosctl services --nodes <node-ip>
```

Or specify the config file explicitly:

```bash
talosctl --talosconfig ./talosconfig health
```

### Using kubectl

Set the `KUBECONFIG` environment variable:

```bash
export KUBECONFIG=./bootstrap-cluster/sandbox/kubeconfig

# Get cluster nodes
kubectl get nodes

# View all pods
kubectl get pods -A

# Check cluster info
kubectl cluster-info
```

Or specify the config file explicitly:

```bash
kubectl --kubeconfig ./kubeconfig get nodes
```

## Credential Security Best Practices

### 1. Never Commit Credentials to Git

The `.gitignore` file already excludes these files:

```gitignore
talosconfig
kubeconfig
controlplane.yaml
```

Ensure these patterns remain in your `.gitignore`.

### 2. Restrict File Permissions

Limit credential file permissions:

```bash
chmod 600 talosconfig
chmod 600 kubeconfig
```

### 3. Use Separate Credentials Per Environment

Each environment (sandbox, staging, production) has its own credentials:

```
bootstrap-cluster/
├── sandbox/
│   ├── talosconfig
│   └── kubeconfig
├── staging/
│   ├── talosconfig
│   └── kubeconfig
└── production/
    ├── talosconfig
    └── kubeconfig
```

Never reuse credentials across environments.

### 4. Rotate Credentials Regularly

Talos certificates have expiration dates. Monitor and rotate before expiry:

```bash
# Check certificate expiration
talosctl config info

# Rotate Kubernetes certificates (automatically handled by Talos)
```

### 5. Use IAM for AWS Secrets Manager Access

Control who can retrieve credentials from AWS Secrets Manager using IAM policies:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:region:account:secret:sandbox_*"
    }
  ]
}
```

## Team Access Patterns

### For New Team Members

1. Ensure they have AWS CLI configured with appropriate IAM permissions
2. Provide them with the environment name (e.g., "sandbox")
3. They retrieve credentials from AWS Secrets Manager:

```bash
# Set environment
export ENV=sandbox

# Retrieve talosconfig
aws secretsmanager get-secret-value \
  --secret-id ${ENV}_talosconfig_yaml \
  --query SecretString --output text | base64 -d > talosconfig

# Retrieve kubeconfig
aws secretsmanager get-secret-value \
  --secret-id ${ENV}_kubeconfig \
  --query SecretString --output text | base64 -d > kubeconfig

# Set environment variables
export TALOSCONFIG=$(pwd)/talosconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Verify access
talosctl version
kubectl get nodes
```

### For CI/CD Pipelines

CI/CD systems can retrieve credentials from AWS Secrets Manager using IAM roles:

```bash
# In GitHub Actions, GitLab CI, etc.
export TALOSCONFIG=$(mktemp)
export KUBECONFIG=$(mktemp)

aws secretsmanager get-secret-value \
  --secret-id ${ENV}_talosconfig_yaml \
  --query SecretString --output text | base64 -d > $TALOSCONFIG

aws secretsmanager get-secret-value \
  --secret-id ${ENV}_kubeconfig \
  --query SecretString --output text | base64 -d > $KUBECONFIG

# Now run kubectl or talosctl commands
kubectl apply -f manifests/
```

## Managing Application Secrets

This template provides a **bare Kubernetes cluster** without application secret management.

For application secrets, you can deploy one of the following solutions on your cluster:

### Option 1: Sealed Secrets

Encrypt secrets in Git using Sealed Secrets:

```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install kubeseal CLI
# See: https://github.com/bitnami-labs/sealed-secrets#kubeseal

# Create and seal a secret
echo -n mypassword | kubectl create secret generic mysecret \
  --dry-run=client --from-file=password=/dev/stdin -o yaml | \
  kubeseal -o yaml > mysealedsecret.yaml

# Commit sealed secret to Git
git add mysealedsecret.yaml
```

### Option 2: External Secrets Operator

Sync secrets from AWS Secrets Manager to Kubernetes:

```bash
# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system --create-namespace

# Create ExternalSecret resource pointing to AWS Secrets Manager
```

### Option 3: HashiCorp Vault

Use Vault for centralized secret management.

## Updating Stored Credentials

If you regenerate cluster credentials, update AWS Secrets Manager:

```bash
# Update talosconfig
aws secretsmanager update-secret \
  --secret-id ${ENV}_talosconfig_yaml \
  --secret-string "$(base64 -w0 talosconfig)"

# Update kubeconfig
aws secretsmanager update-secret \
  --secret-id ${ENV}_kubeconfig \
  --secret-string "$(base64 -w0 kubeconfig)"
```

## Troubleshooting

### "AccessDenied" when retrieving from Secrets Manager

Check your IAM permissions:

```bash
aws iam get-user
aws sts get-caller-identity
```

Verify the secret exists:

```bash
aws secretsmanager list-secrets | grep ${ENV}
```

### "certificate has expired" error

Talos automatically rotates certificates. If you encounter expiry issues:

```bash
# Regenerate kubeconfig
talosctl kubeconfig --force
```

### Lost credentials

If you lose local credentials but they're in AWS Secrets Manager, retrieve them as shown above.

If credentials are completely lost, you may need to bootstrap a new control plane, which requires cluster recreation.

## References

- [Talos Security Documentation](https://www.talos.dev/docs/security/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Kubernetes Secret Management](https://kubernetes.io/docs/concepts/configuration/secret/)
