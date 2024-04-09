module "eks_cluster" {
  source  = "registry.terraform.io/terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = "${var.environment}-workload"
  cluster_version = "1.24"

  subnet_ids = module.vpc.private_subnets

  vpc_id                          = module.vpc.vpc_id
  cluster_endpoint_private_access = true

  // TODO: Disable public access and setup a VPN
  cluster_endpoint_public_access = true
  cluster_security_group_additional_rules = {
    public_access = {
      description = "From Public Connection"
      protocol    = "all"
      from_port   = 0
      to_port     = 65535
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  cluster_timeouts = {
    delete = "30m"
  }

  iam_role_name = "${var.environment}-workload-role"

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 7
  fargate_profiles                       = {
    default = {
      name      = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
      subnet_ids = module.vpc.private_subnets
    }
    kube-system = {
      name      = "kube-system"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
      subnet_ids = module.vpc.private_subnets
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = var.administrator_role_arn
      username = "admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = var.readonly_role_arn
      username = "readonly"
      groups   = ["readonly"]
    },
  ]
}

resource "aws_eks_addon" "coredns" {
  depends_on        = [module.eks_cluster]
  addon_name        = "coredns"
  addon_version     = "v1.8.7-eksbuild.3"
  cluster_name      = module.eks_cluster.cluster_name
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "aws_vpc_cni" {
  addon_name        = "vpc-cni"
  addon_version     = "v1.12.0-eksbuild.1"
  cluster_name      = module.eks_cluster.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [module.eks_cluster]
}

resource "kubernetes_cluster_role_v1" "readonly" {
  metadata {
    name = "readonly"
  }

  rule {
    non_resource_urls = ["*"]
    verbs             = ["get", "list", "watch"]
  }

  rule {
    resources  = ["*"]
    api_groups = [""]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "readonly" {
  metadata {
    name = "readonly"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "readonly"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "readonly"
    namespace = ""
  }
}