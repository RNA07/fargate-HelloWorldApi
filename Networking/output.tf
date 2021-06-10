output vpc_arn {
  value = aws_vpc.main_vpc.arn
  description = "ARN of newly created vpc"
}

output cloud_map_arn {
  value = aws_service_discovery_private_dns_namespace.main.id
  description = "ID of newly created namespace"
}

output VPC_Link_SG {
  value = aws_security_group.main.id
  description = "Security Group for VPC Link"
}
