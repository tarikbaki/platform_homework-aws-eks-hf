# platform_homework-aws-eks-hf

This repository demonstrates application deployment and management with Kubernetes, implementation of GitOps principles, and integration of AWS services in a DevOps context.

## Repository Structure

- **terraform/**: Contains base resource configurations (EKS, RDS, etc.). Environment-specific values are kept in the `config/` folder.
- **kubernetes/manifests/**: Kubernetes deployment and service YAML files for your applications.
- **.gitops/**: ArgoCD application and manifest files for GitOps workflows.

```
terraform/
  ├── eks/
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
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
```

---

## Helm Chart

- **homework-helm**: Specify the AWS ALB ingress certificate here (`alb.ingress.kubernetes.io/` annotation).
- Pod management uses the RollingUpdate strategy:
  ```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  ```
- Environment variables are managed securely via AWS Secrets Manager:
  ```yaml
  env:
    - name: ...
      valueFrom:
        secretKeyRef:
          name: aws-secret-manager
  ```

---

## Requirements

Ensure the following tools are installed:

- **Homebrew**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- **npm**
  ```bash
  brew install npm
  ```
- **Docker**

---

## Local Development & Running

1. Install npm:
   ```bash
   brew install npm
   ```
2. Install npm dependencies:
   ```bash
   npm install
   ```
3. Start the application:
   ```bash
   docker compose -f docker/docker-compose.yml up -d
   ```
4. To start only the database:
   ```bash
   docker compose -f docker/docker-compose.yml up -d homework-db
   ```

### Commit Process

- For conventional commits using commitizen:
  ```bash
  brew install commitizen
  npm run ktlintFormat
  git add .
  cz c
  ```

---

## Argo CD Installation & Management

### Installation

Argo CD is installed using Terraform and Helm:

```hcl
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"
  values           = [file("argocd.yaml")]
}
```

Helm provider configuration example:
```hcl
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
```

Sample `values.yaml` customization:
```yaml
global:
  image:
    tag: "v2.6.6"
dex:
  enabled: false
server:
  extraArgs:
    - --insecure
```

---

### Accessing the Argo CD Web UI

1. Port-forward the argocd-server service:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
2. Retrieve the initial Argo CD admin password:
   ```bash
   kubectl get secrets argocd-initial-admin-secret -o yaml -n argocd
   ```
3. Decode the base64-encoded password:
   ```bash
   echo "<base64-password>" | base64 -d
   ```
4. Log in to the Argo CD web UI using the credentials.

---

## Notes

- All deployments, configurations, and secret management follow best practices for cloud-native DevOps.
- For environment-specific configurations, refer to the `config/` directory.
- For questions or contributions, please open an issue or pull request.
