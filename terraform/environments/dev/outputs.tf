output "instance_ips" {
  description = "Public IPs of created instances"
  value       = module.compute.instance_public_ips
}
