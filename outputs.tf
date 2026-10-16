output "network_name" {
  description = "Имя сети"
  value       = mws_vpc_network.this.network
}

output "network_id" {
  description = "ID ресурса сети"
  value       = mws_vpc_network.this.id
}

output "network_ref" {
  description = "Относительная ссылка на сеть (metadata.id)"
  value       = mws_vpc_network.this.metadata.id
}

output "network_status" {
  description = "Статус сети"
  value       = mws_vpc_network.this.status
}

output "subnets" {
  description = "Подсети: имя => { id, ref, cidr, region }"
  value = {
    for k, s in mws_vpc_subnet.this : k => {
      id     = s.id
      ref    = s.metadata.id
      cidr   = s.cidr
      region = s.status.region
    }
  }
}

output "subnet_refs" {
  description = "Относительные ссылки на подсети: имя => metadata.id"
  value       = { for k, s in mws_vpc_subnet.this : k => s.metadata.id }
}

output "external_addresses" {
  description = "Внешние адреса: имя => { id, ref, ip_address, region }"
  value = {
    for k, a in mws_vpc_external_address.this : k => {
      id         = a.id
      ref        = a.metadata.id
      ip_address = a.status.ip_address
      region     = a.status.region
    }
  }
}

output "external_ips" {
  description = "Внешние IP: имя => ip_address"
  value       = { for k, a in mws_vpc_external_address.this : k => a.status.ip_address }
}

output "egress_nats" {
  description = "Egress NAT-шлюзы: имя => { id, ref, external_ips }"
  value = {
    for k, n in mws_vpc_egress_nat.this : k => {
      id           = n.id
      ref          = n.metadata.id
      external_ips = try([for a in n.status.external.addresses : a.ip_address], [])
    }
  }
}

output "routes" {
  description = "Маршруты: имя => { id, ref }"
  value = {
    for k, r in mws_vpc_route.this : k => {
      id  = r.id
      ref = r.metadata.id
    }
  }
}
