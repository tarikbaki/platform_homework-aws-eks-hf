# platform_homework-aws-eks-hf
deploying and managing applications using Kubernetes, implementing GitOps principles, and integrating AWS services within a DevOps context.

terraform folder contains all resource configuration without environment details. config folder contains environment specific values.


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
