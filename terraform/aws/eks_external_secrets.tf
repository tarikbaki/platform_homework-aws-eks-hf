resource "aws_iam_role" "eks_external_secrets" {
  name = "${var.environment}-workload-eks-external-secrets"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${module.eks_cluster.oidc_provider}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks_cluster.oidc_provider}:aud" = "sts.amazonaws.com",
            "${module.eks_cluster.oidc_provider}:sub" = "system:serviceaccount:default:aws-external-secrets"
          }
        }
      }
    ]
  })
}
resource "aws_iam_policy" "eks_secret_manager" {
  name = "${var.environment}-workload-secret-manager"
  description = "Aws secret manager for EKS"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds",
                "secretsmanager:GetResourcePolicy"
            ],
            "Resource": "*"
        }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "inline_aws_secret_manager" {
  role = aws_iam_role.eks_external_secrets.name
  policy_arn = aws_iam_policy.eks_secret_manager.arn
}
resource "kubernetes_service_account" "eks_workload_external-secrets" {
  metadata {
    name = "aws-external-secrets"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_external_secrets.arn
    }
  }
}
resource "helm_release" "eks_workload_external-secrets" {
  depends_on = [
      module.eks_cluster
  ]
  name  = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"
  namespace = "kube-system"
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "webhook.port"
    value = 9443
  }
}
resource "kubectl_manifest" "eks_workload_external_secretstore" {
    depends_on = [
      helm_release.eks_workload_external-secrets
    ]
    yaml_body = jsonencode({
      apiVersion: "external-secrets.io/v1beta1"
      kind: "SecretStore"
      metadata: {
        name: "aws-external-secretstore"
      }
      spec: {
        provider: {
          aws: {
            service: "SecretsManager"
            region: var.region
            auth: {
              jwt: {
                serviceAccountRef: {
                  name: "aws-external-secrets"
                }
              }
            }
          }
        }
      }
  })
}
locals {
secrets_mapping = {
    homework_backend_db_password = aws_secretsmanager_secret_version.postgres_rds_password_backend.secret_id
    homework_backend_db_endpoint = aws_secretsmanager_secret_version.postgres_rds_endpoint_backend.secret_id
    onesignal_authorization_token = aws_secretsmanager_secret_version.onesignal_authorization_token.secret_id
    onesignal_app_id = aws_secretsmanager_secret_version.onesignal_app_id.secret_id
    firebase_credentials = aws_secretsmanager_secret_version.firebase_credentials.secret_id
    onesignal_staff_app_authorization_token = aws_secretsmanager_secret_version.onesignal_staff_app_authorization_token.secret_id
    onesignal_staff_app_id = aws_secretsmanager_secret_version.onesignal_staff_app_id.secret_id
    firebase_apikey = aws_secretsmanager_secret_version.firebase_apikey.secret_id
    stripe_api_key = aws_secretsmanager_secret_version.stripe_api_key.secret_id
    stripe_signing_secret = aws_secretsmanager_secret_version.stripe_signing_secret.secret_id
}
}
resource "kubectl_manifest" "eks_workload_external_secret" {
    depends_on = [
      helm_release.eks_workload_external-secrets
    ]
    yaml_body = jsonencode({
  apiVersion: "external-secrets.io/v1beta1",
  kind: "ExternalSecret",
  metadata: {
    name: "aws-external-secret"
  },
  spec: {
    refreshInterval: "1h",
    secretStoreRef: {
      name: "aws-external-secretstore",
      kind: "SecretStore"
    },
    target: {
      name: "aws-secret-manager",
      creationPolicy: "Owner"
    },

    data: [
      for secretKey, remoteRefKey in local.secrets_mapping:
        {
          secretKey: secretKey,
          remoteRef: {
            key: remoteRefKey
          }
        }
    ]
  }
 })
}

resource "kubernetes_service_account" "homework_backend_svc_account" {
  metadata {
    labels = {
      "app.kubernetes.io/name" = "homework-backend"
    }
    name = "homework-backend"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.homework_backend_iam_role.arn}"
    }
  }
}


resource "aws_iam_role" "homework_backend_iam_role" {
  name = "${var.environment}-workload-eks-svc-homework-backend"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks_cluster.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks_cluster.oidc_provider}:aud" = "sts.amazonaws.com",
            "${module.eks_cluster.oidc_provider}:sub" = "system:serviceaccount:default:homework-backend"
          }
        }
      }
    ]
  })
}