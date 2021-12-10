variable "bucket" {
  description = "Central infra bucket"
}
variable "ec2_keypair" {
  description = "This is the OPS EC2 SSH key name"
  default     = "infra-key"
}
variable "access_key" {
  description = "This is the AWS access key"
}
variable "secret_key" {
  description = "This is the AWS secret key"
}
variable "region" {
  description = "The AWS region for the resource provisioning"
}
variable "azs" {
  description = "The AWS VPC availability zones for the resource provisioning"
}
variable "image_id" {
  description = "AMI ID"
}
variable "instance_type" {
  description = "Instance type"
}
variable "name" {
  description = "Name of ec2 instance"
}
variable "vpc_id" {
  description = "VPC ID"
}
variable "vpc_cidr_block" {}
variable "aws_account" {}
variable "volume_size" {}