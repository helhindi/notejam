# Notejam [Springboot]
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/maven.yml/badge.svg)
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/dependabot.yml/badge.svg)
## Introduction
This repo is a modified clone of https://github.com/nordcloud/notejam
It aims to add a provisional infrastructure to help develop against and promote to production.

A minimal Github Actions CI job is included in `../.github/wokflows/maven.yml`. Worth adding that I have removed the `mvn test` job due to failing tests.

The infrastructure is WIP and hence specific security pieces such as CloudFront, SSL certificates and Ingress are pending. DB initialisation uses public access (to be fixed). A To-do list is found at the bottom of this README.

![Alt text](./notejam-arch-v0.1.png?raw=true "Notejam proposed architecture v0.1")

## Getting started:
**Note:** The instructions assume an OSX machine with `brew` installed.

From an OSX machine's Terminal; launch the following commands:
```
  git clone -b dev https://github.com/helhindi/notejam.git &&cd spring
```

#### Install `brew`:
```
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
#### Install tools:
Install `'aws-cli' (requires 'python 3.9'), 'terraform', 'kubectl', 'mysql', 'skaffold'` by running:
```
  brew bundle --verbose
  brew link mysql@5.7 && echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.bash_profile (or ~/.zshrc)
  source ~/.bash_profile (or ~/.zshrc)
```

#### Initialise `aws-cli`/`shell`:
Once you've installed `aws-cli` (via `brew`/other); run `aws configure` to setup your credentials and profiles.
`terraform` cli relies on AWS profiles and added to `dev.tfvars` prior to launch.

Further details can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
#### Initialise and create base infrastructure:
```
  terraform init
  terraform plan --vars-file dev.tfvars
```
Once happy with the output; apply the change using:
```
  terraform apply --vars-file dev.tfvars
```

#### Set env vars & initialise the DB:

**Note:** `db_user` & `db_password` should already be in your `dev.tfvars`. (Refer to `terraform` output for `db_host` and `db_name`).
Run the following (remembering to replace all `SET_ME` values):
```
export db_host="SET_ME" db_name="SET_ME" db_user="SET_ME" db_password="SET_ME" db_port="3306"
mysql -h $db_host -u $db_user -p$db_password $db_name < ./new-schema.sql
```

#### Deploy to k8s cluster:
Assuming the EKS cluster is up; [authenticate and connect](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-connection/) via `kubectl` and deploy your code using:
```
  skaffold run (or 'skaffold dev' if you want to see code changes deployed immediately)
```

#### Test deployment:
Start by port forwarding traffic from `notejam-service` to your terminal via:
```
  kubectl port-forward svc/notejam-service 80:8080
  curl localhost:8080
```

---
###### To do:
- CloudFront: Create Distribution with headers restricting access to the ALB ingress (to clients with the correct header)
- Create Route 53 DNS record + ACM crtificates & label the Ingress
- Ingress Controller: Deploy with labels containing `certificate arn` and `host` values. Paying attention to add a condition for CloudFront only access + specific headers
- RDS: Revert to private subnets + Solve execution of DB initialisation & alter the current security group ingress to worker nodes only.
