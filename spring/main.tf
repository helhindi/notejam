terraform {
  required_version = ">= 0.12.0, < 0.14"
}

provider "aws" {
  version = ">= 2.28.1"
  profile = "personal"
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

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "notejam-${var.environment}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.47.0"

  name                 = "notejam-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.2.0/24"]
  enable_nat_gateway   = false
  single_nat_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "tier"                                        = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "tier"                                        = "private"
  }
}

data "aws_subnet_ids" "private" {
    vpc_id = module.vpc.vpc_id
    tags = {
      tier = "private"
    }
}

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "notejam-rds" {
  name        = "notejam-rds-sg"
  description = "RDS (terraform-managed)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "notejam" {
  name       = "notejam"
  subnet_ids = data.aws_subnet_ids.private.ids
}

resource "aws_db_instance" "notejam" {
  allocated_storage         = 20
  engine                    = "mysql"
  engine_version            = "5.7.33"
  instance_class            = "db.t3.micro"
  name                      = "notejam"
  identifier                = "notejam-mysql"
  final_snapshot_identifier = "notejam-final-snapshot"
  publicly_accessible       = true
  db_subnet_group_name      = aws_db_subnet_group.notejam.name
  vpc_security_group_ids    = [aws_security_group.worker_group_mgmt.id, aws_security_group.notejam-rds.id]
  username                  = var.DBUSER
  password                  = var.DBPASSWORD
}

provider "mysql" {
  endpoint = aws_db_instance.notejam.endpoint
  username = aws_db_instance.notejam.username
  password = aws_db_instance.notejam.password
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = var.environment
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t3.medium"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
    },
  ]

workers_group_defaults = {
  root_volume_type                  = "gp2"
}

  map_roles                            = var.map_roles
  map_users                            = var.map_users
  map_accounts                         = var.map_accounts
}

resource "null_resource" "DB-init" {
  provisioner "local-exec" {
    command = "mysql -u ${var.DBUSER} -p${var.DBPASSWORD} -h ${aws_db_instance.notejam.endpoint} < ../schema.sql"
    environment {}
  }
}
