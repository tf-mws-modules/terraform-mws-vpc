variable "project" {
  type        = string
  default     = null
  description = "Путь к проекту. Если не задан, используется проект из настроек провайдера"
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Таймауты операций, применяемые ко всем ресурсам модуля (например, \"30m\")"
}

################################################################################
# Network
################################################################################

variable "network_name" {
  type        = string
  description = "Имя сети"
}

variable "network_description" {
  type        = string
  default     = null
  description = "Описание сети"
}

variable "network_display_name" {
  type        = string
  default     = null
  description = "Отображаемое имя сети"
}

variable "internet_access" {
  type        = bool
  default     = null
  description = "Доступ сети в интернет"
}

variable "mtu" {
  type        = number
  default     = null
  description = "MTU сети в байтах"
}

################################################################################
# Subnets
################################################################################

variable "subnets" {
  type = map(object({
    cidr         = string
    region       = optional(string)
    description  = optional(string)
    display_name = optional(string)
    dhcp_options = optional(object({
      domain_name         = optional(string)
      domain_name_servers = optional(list(string))
      ntp_servers         = optional(list(string))
    }))
  }))
  default     = {}
  description = "Подсети. Ключ карты — имя подсети"

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.cidr, 0))])
    error_message = "Каждая подсеть должна иметь корректный IPv4 CIDR."
  }
}

################################################################################
# External addresses
################################################################################

variable "external_addresses" {
  type = map(object({
    nat_gateway  = optional(string)
    region       = optional(string)
    description  = optional(string)
    display_name = optional(string)
  }))
  default     = {}
  description = "Статические внешние IP-адреса. Ключ карты — имя адреса"
}

################################################################################
# Egress NAT
################################################################################

variable "egress_nats" {
  type = map(object({
    description  = optional(string)
    display_name = optional(string)

    # Внешние адреса для трансляции, в каждом ровно одно из полей:
    #   name — ключ адреса из var.external_addresses;
    #   ref  — ссылка на статический внешний адрес, созданный вне модуля;
    #   spec — спецификация динамического адреса.
    external_addresses = list(object({
      name = optional(string)
      ref  = optional(string)
      spec = optional(object({
        nat_gateway = optional(string)
      }))
    }))

    # Ключи подсетей из var.subnets, для которых выполняется трансляция
    subnets = optional(list(string), [])
    # Дополнительные относительные ссылки на подсети, созданные вне модуля
    subnet_refs = optional(list(string), [])

    ports_per_client = optional(string)
  }))
  default     = {}
  description = "Egress NAT-шлюзы. Ключ карты — имя шлюза"

  validation {
    condition = alltrue([
      for n in values(var.egress_nats) : length(n.external_addresses) > 0 && alltrue([
        for a in n.external_addresses : length(compact([a.name, a.ref, a.spec != null ? "spec" : null])) == 1
      ])
    ])
    error_message = "Для каждого Egress NAT нужен хотя бы один внешний адрес, и в каждом адресе должно быть задано ровно одно из name, ref или spec."
  }

  validation {
    condition     = alltrue([for n in values(var.egress_nats) : length(n.subnets) + length(n.subnet_refs) > 0])
    error_message = "Для каждого Egress NAT нужна хотя бы одна подсеть (subnets или subnet_refs)."
  }
}

################################################################################
# Routes
################################################################################

variable "routes" {
  type = map(object({
    description       = optional(string)
    display_name      = optional(string)
    destination_cidrs = list(string)

    # Ровно одно из полей: ссылка на внутренний IP-адрес или NAT-шлюз
    next_hop_address_ref = optional(string)
    next_hop_nat_gateway = optional(string)
  }))
  default     = {}
  description = "Маршруты. Ключ карты — имя маршрута"

  validation {
    condition = alltrue([
      for r in values(var.routes) : (r.next_hop_address_ref != null) != (r.next_hop_nat_gateway != null)
    ])
    error_message = "Для каждого маршрута должен быть задан ровно один из next_hop_address_ref или next_hop_nat_gateway."
  }

  validation {
    condition = alltrue(flatten([
      for r in values(var.routes) : [for c in r.destination_cidrs : can(cidrhost(c, 0))]
    ]))
    error_message = "destination_cidrs должны содержать корректные CIDR."
  }
}
