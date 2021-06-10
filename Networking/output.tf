output vpc_id {
  value = aws_vpc.main_vpc.id
  description = "VPC id"
}


output private_subnet_id {
  value = aws_subnet.Private-Subnet.id
  description = "Private Subnet id for Fargate Cluster"
}

output Fargate_NameSpace_id {
  value = aws_service_discovery_private_dns_namespace.main.id
  description = "Namespace id"
}

output VPC_Link_id {
  value = aws_apigatewayv2_vpc_link.main.id
  description = "VPC Link Id"
}

output VPC_Link_SG {
  value = aws_security_group.main.id
  description = "Security Group for VPC Link"
}