output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of EC2 instance"
  value       = aws_instance.this.private_ip
}

output "availability_zone" {
  description = "Availability Zone (HAN Local Zone)"
  value       = aws_instance.this.availability_zone
}

output "instance_state" {
  description = "Current state of EC2 instance"
  value       = aws_instance.this.instance_state
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "subnet_id" {
  description = "Public subnet ID in HAN Local Zone"
  value       = aws_subnet.han_public.id
}

output "security_group_id" {
  description = "Security Group ID (zero inbound)"
  value       = aws_security_group.this.id
}

output "schedule_description" {
  description = "Instance schedule"
  value       = "Mon-Fri 8:00-16:00 Hanoi (UTC+7)"
}

output "ssm_command" {
  description = "Command to connect via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}

output "ami_used" {
  description = "AMI ID used"
  value       = aws_instance.this.ami
}

output "public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.this.public_ip
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.this.instance_type
}
