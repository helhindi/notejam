terraform {
  required_version = ">= 0.12.0, < 0.14"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.18.1"

  cidr_block = var.cidr_block

  context = module.this.context
}

module "public_subnets" {
  source = "cloudposse/multi-az-subnets/aws"
  stage               = var.environment
  name                = "${var.app_name} public subnets"
  availability_zones  = data.aws_availability_zones.available.names
  vpc_id              = module.vpc.vpc_id
  cidr_block          = local.public_cidr_block
  type                = "public"
  igw_id              = module.vpc.igw_id
  nat_gateway_enabled = "true"
}

module "private_subnets" {
  source = "cloudposse/multi-az-subnets/aws"
  stage               = var.environment
  name                = "${var.app_name} private subnets"
  availability_zones  = data.aws_availability_zones.available.names
  vpc_id              = module.vpc.vpc_id
  cidr_block          = local.private_cidr_block
  nat_gateway_enabled = "true"
  type                = "private"

  az_ngw_ids = module.public_subnets.az_ngw_ids
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
    cidr_blocks = ["0.0.0.0/0"]
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
  subnet_ids = values(module.public_subnets.az_subnet_ids)[*]
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
  username                  = var.db_user
  password                  = var.db_password
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  subnets         = values(module.private_subnets.az_subnet_ids)[*]

  tags = {
    Environment = var.environment
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t3.small"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
    },
  ]

workers_group_defaults = {
  root_volume_type                  = "gp2"
}

  map_roles                         = var.map_roles
  map_users                         = var.map_users
  map_accounts                      = var.map_accounts
}
