data "aws_ami" "os" {
  owners      = ["540036508848"] # Sidero Labs
  most_recent = true
  name_regex  = "^talos-v${var.talos_version}-${data.aws_availability_zones.available.id}-amd64$"
}

locals {
  cluster_required_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

module "control_plane_nodes" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6.1"

  for_each = var.control_plane.instances

  name                        = "${var.cluster_name}-${each.key}"
  ami                         = each.value.ami_id == null ? data.aws_ami.os.id : each.value.ami_id
  monitoring                  = true
  instance_type               = each.value.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  subnet_id                   = element(module.vpc.public_subnets, each.value.subnet_index)
  iam_role_use_name_prefix    = false
  create_iam_instance_profile = false
  tags                        = merge(local.common_tags, local.cluster_required_tags, each.value.tags)

  vpc_security_group_ids = [module.cluster_sg.security_group_id]

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = each.value.disk_size
    }
  ]

}

