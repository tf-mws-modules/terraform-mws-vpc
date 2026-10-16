################################################################################
# Network
################################################################################

resource "mws_vpc_network" "this" {
  network         = var.network_name
  project         = var.project
  internet_access = var.internet_access
  mtu             = var.mtu

  metadata = var.network_description != null || var.network_display_name != null ? {
    description  = var.network_description
    display_name = var.network_display_name
  } : null

  timeouts = var.timeouts
}

################################################################################
# Subnets
################################################################################

resource "mws_vpc_subnet" "this" {
  for_each = var.subnets

  subnet  = each.key
  network = mws_vpc_network.this.network
  project = var.project
  cidr    = each.value.cidr
  region  = each.value.region

  dhcp_options = each.value.dhcp_options

  metadata = each.value.description != null || each.value.display_name != null ? {
    description  = each.value.description
    display_name = each.value.display_name
  } : null

  timeouts = var.timeouts
}

################################################################################
# External addresses
################################################################################

resource "mws_vpc_external_address" "this" {
  for_each = var.external_addresses

  external_address = each.key
  project          = var.project
  nat_gateway      = each.value.nat_gateway
  region           = each.value.region

  metadata = each.value.description != null || each.value.display_name != null ? {
    description  = each.value.description
    display_name = each.value.display_name
  } : null

  timeouts = var.timeouts
}

################################################################################
# Egress NAT
################################################################################

resource "mws_vpc_egress_nat" "this" {
  for_each = var.egress_nats

  egress_nat = each.key
  network    = mws_vpc_network.this.network
  project    = var.project

  external = {
    addresses = [
      for a in each.value.external_addresses : {
        ref  = a.name != null ? mws_vpc_external_address.this[a.name].metadata.id : a.ref
        spec = a.spec
      }
    ]
  }

  internal = {
    subnets = concat(
      [for s in each.value.subnets : mws_vpc_subnet.this[s].metadata.id],
      each.value.subnet_refs,
    )
  }

  port_allocation = each.value.ports_per_client != null ? {
    ports_per_client = each.value.ports_per_client
  } : null

  metadata = each.value.description != null || each.value.display_name != null ? {
    description  = each.value.description
    display_name = each.value.display_name
  } : null

  timeouts = var.timeouts
}

################################################################################
# Routes
################################################################################

resource "mws_vpc_route" "this" {
  for_each = var.routes

  route   = each.key
  network = mws_vpc_network.this.network
  project = var.project

  destination = {
    spec = {
      cidrs = each.value.destination_cidrs
    }
  }

  next_hop = {
    address     = each.value.next_hop_address_ref != null ? { ref = each.value.next_hop_address_ref } : null
    nat_gateway = each.value.next_hop_nat_gateway
  }

  metadata = each.value.description != null || each.value.display_name != null ? {
    description  = each.value.description
    display_name = each.value.display_name
  } : null

  timeouts = var.timeouts
}
