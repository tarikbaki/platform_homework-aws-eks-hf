locals {
  cidr_subnets = [for cidr_block in cidrsubnets(var.cidr, 8, 8, 8) : cidrsubnets(cidr_block, 4, 4)]
}

module "vpc" {
  source                             = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version                            = "3.18.1"

  name                               = "homework-${var.environment}"
  cidr                               = var.cidr
  azs                                = var.vpc_azs
  private_subnets                    = local.cidr_subnets[0]
  database_subnets                   = local.cidr_subnets[1]
  public_subnets                     = local.cidr_subnets[2]
  create_database_subnet_route_table = true
  enable_nat_gateway                 = true

  # DNS and DHCP Conf
  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "${var.region}.compute.internal"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  enable_flow_log = false

  private_subnet_tags = {
    "Tier"                            = "Private"
    "kubernetes.io/cluster/workload"  = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }

  database_subnet_tags = {
    "Tier" = "Database"
  }
}