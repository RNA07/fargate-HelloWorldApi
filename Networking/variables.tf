variable "environment" {
  type        = string
  description = "Application environment"
}

variable "app_name" {
  type        = string
  description = "Application envirnameonment"
}


variable "region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block range for vpc"
}