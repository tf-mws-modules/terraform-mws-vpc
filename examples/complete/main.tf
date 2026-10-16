terraform {
  required_version = ">= 1.11"

  required_providers {
    mws = {
      source  = "mws-cloud/mws"
      version = ">= 0.0.35"
    }
  }
}

provider "mws" {}

module "vpc" {
  source = "../.."

  network_name         = "example-network"
  network_display_name = "Example network"

  subnets = {
    "example-private-a" = {
      cidr = "10.10.0.0/24"
      dhcp_options = {
        domain_name_servers = ["10.10.0.2"]
      }
    }
    "example-private-b" = {
      cidr        = "10.10.1.0/24"
      description = "Private subnet B"
    }
  }

  external_addresses = {
    "example-nat-address" = {
      display_name = "Example NAT address"
    }
  }

  egress_nats = {
    "example-egress-nat" = {
      display_name = "Example Egress NAT"
      external_addresses = [
        { name = "example-nat-address" },
      ]
      subnets = ["example-private-a", "example-private-b"]
    }
  }

  routes = {
    "example-onprem" = {
      destination_cidrs    = ["172.16.0.0/12"]
      next_hop_address_ref = "addresses/example-vpn-gateway"
    }
  }
}

output "vpc" {
  value = module.vpc
}
