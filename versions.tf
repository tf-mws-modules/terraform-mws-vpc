terraform {
  required_version = ">= 1.11"

  required_providers {
    mws = {
      source  = "mws-cloud/mws"
      version = ">= 0.0.35"
    }
  }
}
