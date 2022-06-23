# The block below configures Terraform to use the 'remote' backend with Terraform Cloud.
# For more information, see https://www.terraform.io/docs/backends/types/remote.html
terraform {
  backend "remote" {
    organization = "l3av"

    workspaces {
      name = "private_cloud-dev"
    }
  }

  required_version = ">= 0.13.0"
}
