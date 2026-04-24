# ════════════════════════════════════════════════════════════
# Compute Module — EC2 Instances with hardening bootstrap
# Demonstrates: cloud-init, encrypted volumes, SSM, tagging
# ════════════════════════════════════════════════════════════

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_groups" {
  description = "Security group IDs"
  type        = list(string)
}

variable "user_data" {
  description = "Cloud-init user data"
  type        = string
  default     = ""
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_groups
  user_data              = var.user_data
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  monitoring = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags = {
      Name = "devops-toolkit-root-${count.index + 1}"
    }
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 enforcement
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  tags = {
    Name        = "devops-toolkit-${count.index + 1}"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Role        = "app-server"
  }
}

# Minimal IAM role for SSM access (no hardcoded credentials)
resource "aws_iam_role" "ec2_role" {
  name = "devops-toolkit-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devops-toolkit-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

output "instance_public_ips" {
  description = "Public IP addresses"
  value       = aws_instance.this[*].public_ip
}

output "instance_ids" {
  description = "Instance IDs"
  value       = aws_instance.this[*].id
}
