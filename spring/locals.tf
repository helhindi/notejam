locals {
  cluster_name       = "notejam-${var.environment}"

  public_cidr_block  = cidrsubnet(var.cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(var.cidr_block, 1, 1)

  charts_incubator_repo   = "https://charts.helm.sh/incubator"

  tags_map = merge(
    {
      environment         = var.environment
      product             = var.app_name
    },
  )
}
