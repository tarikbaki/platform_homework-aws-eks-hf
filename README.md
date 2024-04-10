# platform_homework-aws-eks-hf
deploying and managing applications using Kubernetes, implementing GitOps principles, and integrating AWS services within a DevOps context.

Terraform folder contains all resource configuration without environment details. config folder contains environment specific values.

***
terraform/
│
├── eks/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── rds/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

kubernetes/
└── manifests/
    ├── deployment1.yaml
    ├── deployment2.yaml
    ├── service1.yaml
    └── service2.yaml

.gitops/
├── argocd-app.yaml
├── README.md
└── manifests/
    ├── deployment1.yaml
    ├── deployment2.yaml
    ├── service1.yaml
    └── service2.yaml

***

***


Helm chart

homework-helm The aws ingress certificate should be written here. ingress certificate : alb.ingress.kubernetes.io/

With the rolling method, pod management is carried out according to the increase and decrease in capacity.

strategy: type: RollingUpdate rollingUpdate: maxSurge: 1 maxUnavailable: 0

The following env information is kept secret by aws secret manager. secretKeyRef: name: aws-secret-manager env:

***

Requirements

brew
To install brew /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")

npm
To install npm brew install npm

docker

Local Build

brew install npm To install npm
npm install For applying json package operations
docker compose -f docker/docker-compose.yml up -d to run application
docker compose -f docker/docker-compose.yml up -d homework-db to run db only
Committing your changes

To use commitizen you need to install using brew install commitizen
Then npm run ktlintFormat
Then git add .
Then cz c

***


declare everything, including the installation of Argo CD and the configuration of our application on Argo CD. We will use Terraform to install the ArgoCD
Create a GKE cluster.
Install Argo CD on it.
Now, let’s look at the Terraform configuration.
setup.yaml
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"
  values           = [file("argocd.yaml")]
}
# helm install argocd -n argocd -f values/argocd.yaml
provider.tf
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.5.1"
    }
  }
}
values.yaml
---
global:
  image:
    tag: "v2.6.6"

dex:
  enabled: false

server:
  extraArgs:
    - --insecure

***
Accessing the Argo CD Web UI
To access the Argo CD Web UI, you need to port-forward argocd-server service.

Run the following command to get the password
apple@Ravindra-Singh ~ % k get secrets argocd-initial-admin-secret -o yam -n argocd

Let’s decode base64 encoded string
echo “Z1RpcFFuUjc4UmI4bTliNw==” | base64 -d
Now let’s log in using the credentials.


***

***
