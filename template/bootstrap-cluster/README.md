# Bootstrap Talos

After deploying infrastructure using Terraform, we can proceed with configuring Talos and bootstrapping the Kubernetes cluster.

Terraform is solely utilized for deploying infrastructure. Any subsequent configuration of Talos is done using Taskfile tasks.

To view a list of tasks and their descriptions, navigate to the `bootstrap-cluster` directory and execute `task`.

Note that there is a directory for each environment: sandbox, staging, and production.

We recommend opening the AWS serial console for each EC2 instance to monitor the bootstrap process.

## Bootstrapping Talos

1. Navigate to the bootstrap-cluster directory and set the environment:

   ```shell
   cd bootstrap-cluster
   export ENV=sandbox
   ```

2. Review the `.env` file for the given environment:

   ```shell
   CONTROL_PLANE_ENDPOINT: "https://k8s.sandbox.{{ copier__domain_name }}:6443"
   CLUSTER_NAME: "{{ copier__project_dash }}-sandbox"
   ```

   Note that we use a Talos factory image. This image contains a system extension that provides the ECR credential provider.

   ```
   siderolabs/ecr-credential-provider (v1.28.1)

       This system extension provides a binary which implements Kubelet's
       CredentialProvider API to authenticate against AWS' Elastic Container
       Registry and pull images.
   ```

3. Bootstrap Talos with the following command:

   ```
   task talos:bootstrap
   ```

   To understand what this task will do, examine the Taskfile configuration:

   ```yaml
   bootstrap:
     desc: |
       Run all tasks required to bootstrap the Talos and Kubernetes cluster.
     requires:
       vars: [ENV]
     cmds:
       - task: generate_configs
       - task: set_node_ips
       - task: store_controlplane_config
       - task: store_talosconfig
       - task: apply_talos_config
       - sleep 60
       - task: bootstrap_kubernetes
       - sleep 60
       - task: generate_kubeconfig
       - task: store_kubeconfig
       - task: upgrade_talos
   ```

   It takes a few minutes for the cluster nodes to register as etcd members and synchronize.

   When the bootstrap completes successfully, you should see output similar to:

   ```
   Upgrading Talos on <node-public-ip>
   watching nodes: [<node-public-ip>]
       * <node-public-ip>: post check passed
   ```

   This indicates the Talos upgrade has completed successfully.

   If the cluster fails to bootstrap, refer to the Troubleshooting section below.

4. Verify the health of your cluster with:

    ```shell
    task talos:health
    ```

5. Test kubectl access:

   ```shell
   eval $(task talos:kubeconfig)
   kubectl cluster-info
   ```

   This should return output similar to the following:

   ```shell
   $ kubectl cluster-info
   Kubernetes control plane is running at https://k8s.sandbox.{{ copier__domain_name }}:6443
   CoreDNS is running at https://k8s.sandbox.{{ copier__domain_name }}:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

   To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
   ```

## Troubleshooting

### Bootstrap fails with "secret already exists"

If you see an error like:
```
An error occurred (ResourceExistsException) when calling the CreateSecret operation:
The operation failed because the secret sandbox_talosconfig_yaml already exists.
```

This means you've already run bootstrap before. To restart the bootstrap process:

1. Delete existing secrets and configs:
   ```shell
   task talos:reset_config
   ```

2. Run bootstrap again:
   ```shell
   task talos:bootstrap
   ```

**Note:** This is intentionally designed to fail loudly to prevent accidentally overwriting credentials for an existing cluster.

### Bootstrap fails completely

If bootstrapping Talos fails, we recommend resetting the config files and recreating EC2 instances before trying again.

1. Reset config and state with `task talos:reset_config` for the given environment.

2. Destroy and recreate EC2 instances:

   ```shell
   cd ../terraform/$ENV/
   tofu destroy \
     -target "module.cluster.module.control_plane_nodes[0].aws_instance.this[0]" \
     -target "module.cluster.module.control_plane_nodes[1].aws_instance.this[0]" \
     -target "module.cluster.module.control_plane_nodes[2].aws_instance.this[0]"
   tofu plan -out="tfplan.out"
   tofu apply tfplan.out
   ```

3. Try bootstrapping again from step 3.
