
environment = "dev"
region = "ap-southeast-2"

NetworkStackVpcLinkId = "e3a49d"
VPCLinkSG = "sg-06f3a820e26cd54c7"
app_name = "HelloWorld"
containter_name = "api"
image_URI = "800376264384.dkr.ecr.ap-southeast-2.amazonaws.com/amplify-continerexample-dev-51617-api-containerf8a1724b-api"
app_port = 8080
FargateNameSpaceID = "ns-kwp4dqjy3xusuore"
vpc_cidr_block = "192.168.0.0/16" 
vpc_id = "vpc-09dd61335bb73489c"
private_subnet_ids = ["subnet-08ab00dbe20e94368"]
tags = {
  cluster = "fargate_cluster"
  created_by = "Terrafrom"
}