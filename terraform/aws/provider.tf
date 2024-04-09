terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.46"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.16"
    }
    helm = {
      source = "hashicorp/helm"
      version = ">= 2.7"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}



provider "aws" {
  region = var.region

  assume_role {
    session_name = var.assume_role_session_name
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role_name}"
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.eks_cluster.cluster_name,
      "--role", "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role_name}",
      "--region", var.region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", module.eks_cluster.cluster_name,
        "--role", "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role_name}",
        "--region", var.region
      ]
    }
  }
}

provider "kubectl" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", "${var.environment}-workload",
      "--role", "arn:aws:iam::${var.aws_account_id}:role/${var.assume_role_name}"
    ]
  }
}
