variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-008f5d46f9a5d6898"
}

variable "instance_type" {
  description = "Instance type for web server"
  type        = string
  default     = "t3.medium"
}

variable "db_instance_type" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.medium"
}

variable "backend_port" {
  description = "Backend application port"
  type        = number
  default     = 3001
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "durga-windows"
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
