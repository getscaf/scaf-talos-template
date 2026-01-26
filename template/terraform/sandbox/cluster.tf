module "cluster" {
  source               = "../modules/base"
  environment          = "sandbox"
  cluster_name         = "{{ copier__project_dash }}-sandbox"
  domain_name          = "sandbox.{{ copier__domain_name }}"
  cluster_domain_name  = "k8s.sandbox.{{ copier__domain_name }}"
  existing_hosted_zone = module.global_variables.existing_hosted_zone
  control_plane = {
    instances = {
      # Each instance can be independently managed and upgraded
      "0" = {
        instance_type = "t3a.medium"  # 2 vCPUs, 4 GiB RAM, $0.0376 per Hour
        disk_size     = 100            # Size in GB
        subnet_index  = 0              # Availability zone index
        # NB!: set ami_id to prevent instance recreation when the latest ami
        # changes, eg:
        # ami_id = "ami-09d22b42af049d453"
      }
    }
  }

  # NB!: limit admin_allowed_ips to a set of trusted
  # public ip addresses. Both variables are comma separated lists of ips.
  # admin_allowed_ips = "10.0.0.1/32,10.0.0.2/32"
}
