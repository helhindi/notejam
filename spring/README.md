# Notejam [Springboot]
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/maven.yml/badge.svg)
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/dependabot.yml/badge.svg)
## Introduction
This repo is a modified clone of https://github.com/nordcloud/notejam with modifications made to the `spring` directory.
It aims to add a provisional infrastructure to help develop against and promote to production.

A minimal Github Actions CI job is included in `../.github/wokflows/maven.yml`. Worth adding that I have removed the `mvn test` job due to failing tests.

The infrastructure is WIP and hence specific security pieces such as CloudFront, SSL certificates and Ingress are pending. DB initialisation uses public access (to be fixed). A To-do list is found at the bottom of this README.

![Alt text](./notejam-arch-v0.1.png?raw=true "Notejam proposed architecture v0.1")

## Getting started:
**Note:** The instructions assume an OSX machine with `brew` installed.

From an OSX machine's Terminal; launch the following commands:
```
  git clone -b dev https://github.com/helhindi/notejam.git
  cd notejam/spring
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
**Note:** `terraform` cli relies on AWS profiles. A named AWS profile is required within `dev.tfvars`.

Further details can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
#### Initialise and create base infrastructure:
Modify `./dev.tfvars` and set `profile, environment, cid_block, db_user & db_password`

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
Run the following after replacing all `SET_ME` values:
```
export db_host="SET_ME" db_name="SET_ME" db_user="SET_ME" db_password="SET_ME" db_port="3306"
mysql -h $db_host -u $db_user -p$db_password $db_name < ./new-schema.sql
```
Substitute `ConfigMap` vars with the above:
```
sed -i.bak -e "s|DB_NAME|$db_name|" \
           -e "s|DB_HOST|$db_host|" \
           -e "s|DB_PORT|$db_port|" \
           -e "s|DB_USER|$db_user|" \
           -e "s|DB_PASSWORD|$db_password|" deployment.yml
```
#### Deploy to k8s cluster:
Assuming the EKS cluster is up; [authenticate and connect](https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-connection/) via `kubectl` and deploy your code using:
```
  skaffold run (or 'skaffold dev' if you want to see code changes deployed immediately)
```

#### Test deployment:
Query the `notejam-service` URL via:
```
  kubectl -n default get svc notejam-service -o jsonpath='{.status.loadBalancer.ingress[*].hostname}'
```
Visit or `curl` the URL or run `kubectl get pods` to check the underlying hosts.

---
###### To do:
1. **Logging/Monitoring:** (This was missed due to time) Use AWS CloudWatch logs + Container Insights to handle this.
2. **CloudFront:** Create Distribution with headers restricting access to the ALB ingress (to clients with the correct header).
3. **Route 53/ACM crtificates:** Create records & label the Ingress.
4. **Ingress Controller:** Deploy with labels containing `certificate arn` and `host` values. Paying attention to add a condition for CloudFront only access + specific headers.
5. **RDS:** Revert to private subnets + Solve execution of DB initialisation & alter the current security group ingress to worker nodes only.
6. **Docker registry:** Switch to ECR by creating a repo and modify registry/image references.
