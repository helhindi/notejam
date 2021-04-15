provider "aws" {
  version = ">= 2.28.1"
  profile = var.profile
  region  = var.region
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  config_path            = "~/.kube/config"
  load_config_file       = false
  version                = "~> 1.11"
}

provider "mysql" {
  endpoint = aws_db_instance.notejam.endpoint
  username = aws_db_instance.notejam.username
  password = aws_db_instance.notejam.password
}
