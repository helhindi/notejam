# flask-pg-app
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/maven.yml/badge.svg)
![GitHub Actions status](https://github.com/helhindi/notejam/actions/workflows/dependabot.yml/badge.svg)
## Introduction


**Note:** The instructions assume an OSX machine with `brew` installed.

## Getting Started

#### Clone repo & install pre-req tools:
From an OSX machine's Terminal; launch the following commands:
```
  git clone https://github.com/helhindi/notejam.git &&cd spring
```

#### Install `brew`:
```
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
#### Install tools:
Install [`'aws-cli' (requires 'Python 3.9'), 'terraform', 'kubectl', 'mysql', 'skaffold'`] by running:
```
  brew bundle --verbose
  brew link mysql@5.7 && echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.bash_profile (or ~/.zshrc)
  source ~/.bash_profile (or ~/.zshrc)
```

#### Initialise `aws-cli`:
Once you've installed `aws-cli` (via `brew`/other); run `aws configure` to setup your credentials and profiles.
`terraform` cli relies on AWS profiles and added to `dev.tfvars` prior to launch.

Refer to https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html for details of adding a profile in your `~/.aws/credentials` file

## Initialise and create base infrastructure:
```
  terraform init
  terraform plan --vars-file dev.tfvars
```
Once happy with the above plan output; apply the change using:
```
  terraform apply --vars-file dev.tfvars
```
Once the EKS cluster is up; authenticate and connect to your cluster via `kubectl` and deploy your code using:
```
  skaffold run (or 'skaffold dev' if you want to see code changes deployed immediately)
```

## Test web service deployment:
Start by port forwarding traffic from `notepad-service` to your terminal via:
```
  kubectl port-forward svc/notepad-service 80:8080
```
To test the http status code from `notepad-service`; run:
```
  curl -o -I -L -s -w "%{http_code}" localhost:8080
```
