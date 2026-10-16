# terraform-mws-vpc

Terraform-модуль для создания и управления VPC в MWS Cloud Platform:

| Ресурс | Назначение |
|---|---|
| `mws_vpc_network` | Сеть |
| `mws_vpc_external_address` | Статические внешние IP-адреса (`var.external_addresses`) |
| `mws_vpc_subnet` | Подсети (`var.subnets`) |
| `mws_vpc_egress_nat` | Egress NAT-шлюзы (`var.egress_nats`) |
| `mws_vpc_route` | Маршруты (`var.routes`) |

Внешние адреса, подсети, NAT-шлюзы и маршруты задаются картами, где ключ — имя ресурса в MWS.
Поэтому добавление или удаление одного элемента не пересоздаёт остальные.

## Требования

- Terraform >= 1.11
- Провайдер `mws-cloud/mws` >= 0.0.35

Провайдер распространяется через зеркало MWS. Добавьте его в `~/.terraformrc`:

```hcl
provider_installation {
  network_mirror {
    url     = "https://storage.mwsapis.ru/mws-terraform/"
    include = ["registry.terraform.io/mws-cloud/*"]
  }
  direct {
    exclude = ["registry.terraform.io/mws-cloud/*"]
  }
}
```

## Использование

```hcl
module "vpc" {
  source = "git::https://gitlab.infra.ab-payments.ru/infrastructure/terraform-mws-vpc.git?ref=<tag>"

  network_name = "prod"

  subnets = {
    "prod-private-a" = { cidr = "10.10.0.0/24" }
    "prod-private-b" = {
      cidr = "10.10.1.0/24"
      dhcp_options = {
        domain_name_servers = ["10.10.0.2"]
      }
    }
  }

  external_addresses = {
    "prod-nat-ip" = {}
  }

  egress_nats = {
    "prod-egress" = {
      external_addresses = [
        { name = "prod-nat-ip" }, # адрес из var.external_addresses
        # { ref = "..." },        # или адрес, созданный вне модуля
        # { spec = {} },          # или динамический адрес
      ]
      subnets          = ["prod-private-a", "prod-private-b"] # ключи из var.subnets
      ports_per_client = "1024"
    }
  }

  routes = {
    "prod-onprem" = {
      destination_cidrs    = ["172.16.0.0/12"]
      next_hop_address_ref = mws_vpc_address.vpn.id
      # или next_hop_nat_gateway = "natGateways/..."
    }
  }
}
```

Полный пример находится в [examples/complete](examples/complete).

## Входные переменные

| Имя | Тип | По умолчанию | Описание |
|---|---|---|---|
| `network_name` | `string` | — | Имя сети |
| `network_description` | `string` | `null` | Описание сети |
| `network_display_name` | `string` | `null` | Отображаемое имя сети |
| `internet_access` | `bool` | `null` | Доступ сети в интернет |
| `mtu` | `number` | `null` | MTU сети |
| `project` | `string` | `null` | Путь к проекту; по умолчанию берётся из провайдера |
| `timeouts` | `object({create, update, delete})` | `null` | Таймауты для всех ресурсов модуля |
| `external_addresses` | `map(object)` | `{}` | Статические внешние IP: `nat_gateway`, `region`, `description`, `display_name` |
| `subnets` | `map(object)` | `{}` | Подсети: `cidr`, `region`, `description`, `display_name`, `dhcp_options` |
| `egress_nats` | `map(object)` | `{}` | Egress NAT: `external_addresses` (в каждом элементе ровно одно из `name` — ключ `var.external_addresses`, `ref`, `spec`), `subnets` (ключи `var.subnets`), `subnet_refs` (внешние ссылки), `ports_per_client`, `description`, `display_name` |
| `routes` | `map(object)` | `{}` | Маршруты: `destination_cidrs` и ровно одно из `next_hop_address_ref` / `next_hop_nat_gateway`; также `description`, `display_name` |

## Выходные значения

| Имя | Описание |
|---|---|
| `network_name` | Имя сети |
| `network_id` | ID ресурса сети |
| `network_ref` | Относительная ссылка на сеть (`metadata.id`) |
| `network_status` | Статус сети |
| `subnets` | Подсети: имя → `{ id, ref, cidr, region }` |
| `subnet_refs` | Подсети: имя → `metadata.id` |
| `external_addresses` | Внешние адреса: имя → `{ id, ref, ip_address, region }` |
| `external_ips` | Внешние адреса: имя → `ip_address` |
| `egress_nats` | NAT-шлюзы: имя → `{ id, ref, external_ips }` |
| `routes` | Маршруты: имя → `{ id, ref }` |

## Ограничения

Внутренние адреса (`mws_vpc_address`) модуль не создаёт.
Их создают снаружи и передают в маршруты через `next_hop_address_ref`.
