# ── General ────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Name prefix used for tagging resources"
  type        = string
  default     = "techstartup"
}

variable "my_ip" {
  description = "Current public IP address in CIDR format"
  type        = string
  default     = "102.208.115.89/32"
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

# ── Instances ──────────────────────────────────────────────────────────────────

variable "bastion_instance_type" {
  description = "Instance type for the Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "Instance type for the Backend server"
  type        = string
  default     = "t3.micro"
}

variable "mongodb_instance_type" {
  description = "Instance type for the MongoDB server"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name to give the AWS key pair created for SSH access"
  type        = string
  default     = "newly"
}