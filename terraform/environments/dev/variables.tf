variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ssh_key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}
