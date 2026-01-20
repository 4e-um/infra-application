# =============================================================================
# Remote State from Bootstrap
# =============================================================================

data "terraform_remote_state" "bootstrap" {
  backend = "remote"

  config = {
    organization = var.terraform_cloud_org
    workspaces = {
      name = var.bootstrap_workspace_name
    }
  }
}

# =============================================================================
# Local values from bootstrap outputs
# =============================================================================

locals {
  # Project
  project_id = data.terraform_remote_state.bootstrap.outputs.project_id

  # VPC
  vpc_id                 = data.terraform_remote_state.bootstrap.outputs.vpc_id
  vpc_name               = data.terraform_remote_state.bootstrap.outputs.vpc_name
  vpc_self_link          = data.terraform_remote_state.bootstrap.outputs.vpc_self_link
  main_subnet_id         = data.terraform_remote_state.bootstrap.outputs.main_subnet_id
  main_subnet_name       = data.terraform_remote_state.bootstrap.outputs.main_subnet_name
  main_subnet_self_link = data.terraform_remote_state.bootstrap.outputs.main_subnet_self_link
  region                = data.terraform_remote_state.bootstrap.outputs.region
}
