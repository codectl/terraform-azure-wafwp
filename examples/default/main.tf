module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "policy" {
  source  = "codectl/wafwp/azure"
  version = "~> 1.0"

  policy = {
    name                = module.naming.web_application_firewall_policy.name
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    policy_settings = {
      enabled = true
      mode    = "Prevention"
    }
    managed_rules = {
      managed_rule_sets = {
        owasp = {
          type    = "OWASP"
          version = "3.2"
        }
      }
    }
  }
}
