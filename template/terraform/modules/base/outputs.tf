output "control_plane_nodes_public_ips" {
  description = "The public ip addresses of the control plane nodes."
  value       = join(",", module.control_plane_nodes.*.public_ip)
}

output "control_plane_nodes_private_ips" {
  description = "The private ip addresses of the control plane nodes."
  value       = join(",", module.control_plane_nodes.*.private_ip)
}
