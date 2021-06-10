variable "region" {
  type = string
  description = "AWS Region"
}
variable "environment" {
  type = string
  description = "The http api environment"
}

variable "containter_name" {
  type = string
  description = "The Container Name"
}
variable "app_name" {
  type = string
  description = "The Application Name"
}

variable "NetworkStackVpcLinkId" {
  type = string
  description = "the VPC link"
}

variable "VPCLinkSG" {
  type = string
  description = "VPC link security group"
}

variable "FargateNameSpaceID" {
  type = string
  description = "The cloudmap service"
}
variable "image_URI" {
  type = string
  description = "The container app image"
}

variable "app_port" {
  type = number
  description = "The container port number"
}
variable "vpc_cidr_block" {
  type = string
  description = "CIDR Block"
}
variable "vpc_id" {
  type = string
  description = "VPC ID"
}
variable "tags" {
  type = map(string)
  description = "Tags to attach to the resources"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "VPC Private Subnet ids"
}