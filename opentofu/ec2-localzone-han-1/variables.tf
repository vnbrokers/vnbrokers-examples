variable "region" {
  description = "AWS region (parent region of HAN Local Zone)"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "vnbrokers"
}

variable "han_zone" {
  description = "Hanoi Local Zone name"
  type        = string
  default     = "ap-southeast-1-han-1a"
}

variable "instance_type" {
  description = "EC2 instance type (must be available in HAN Local Zone: C7i, M7i, R7i)"
  type        = string
  default     = "c7i.large"
}

variable "schedule_start_hour" {
  description = "Start hour UTC (1 = 8AM Hanoi)"
  type        = number
  default     = 1
}

variable "schedule_stop_hour" {
  description = "Stop hour UTC (9 = 4PM Hanoi)"
  type        = number
  default     = 9
}

variable "schedule_days" {
  description = "Days of week for schedule"
  type        = string
  default     = "MON-FRI"
}

variable "ami_name_pattern" {
  description = "Pattern to match Amazon Linux 2023 AMI"
  type        = string
  default     = "al2023-ami-*-kernel-6.1-x86_64"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Public subnet CIDR block in HAN Local Zone"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ebs_volume_size" {
  description = "EBS root volume size in GB (AL2023 AMI snapshot requires >= 30GB)"
  type        = number
  default     = 30
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}
